module radiant_aux(
        input CTRL_CLK,
        input CTRL_DATA,
        input [11:0] MONTIMING_P,
        input [11:0] MONTIMING_N,
        output MONTIMINGOUT_P,
        output MONTIMINGOUT_N,
        input SRCLKIN,
		input RAMPIN,
		input SS_INCRIN,
		input SCLKIN,
		output [11:0] SCLK,
		output [11:0] SS_INCR,		
		output [11:0] RAMP,
        output [11:0] SRCLK_P,
        output [11:0] SRCLK_N,
		output [4:0] WR0,
		output [4:0] WR1,
		output [4:0] WR2,
		output [4:0] WR3,
		output [4:0] WR4,
		output [4:0] WR5,
		output [4:0] WR6,
		output [4:0] WR7,
		output [4:0] WR8,
		output [4:0] WR9,
		output [4:0] WR10,
		output [4:0] WR11,
		input [9:0] WRIN,
		output [3:0] LED
);
	// This ISN'T actually used here. The inversion is fixed at the main FPGA on a channel-by-channel
	// basis. It's just here for reference.
	// MONTIMING inverted pins:
	// P0		1
	// not P1	0
	// not P2	0
	// not P3	0
	// not P4	0
	// P5		1
	// P6		1
	// P7		1
	// not P8	0
	// not P9	0
	// P10		1
	// not P11 	0
	// = 0100_1110_0001 = 4E1.
	parameter [11:0] MT_INVERT = 12'b010011100001;
	// P0		1
	// P1		1
	// P2		1
	// P3		1
	// P4		1
	// not P5	0
	// not P6	0
	// P7		1
	// not P8	0
	// not P9	0
	// not P10	0
	// P11		1
	// or 1000 1001 1111
	parameter [11:0] SC_INVERT = 12'b100010011111;

                reg [3:0] ctrl_sel = {4{1'b0}};
                always @(posedge CTRL_CLK) ctrl_sel <= {ctrl_sel[2:0],CTRL_DATA};

                wire [15:0] montiming_internal;
				assign montiming_internal[12] = montiming_internal[4];
				assign montiming_internal[13] = montiming_internal[5];
				assign montiming_internal[14] = montiming_internal[6];
				assign montiming_internal[15] = montiming_internal[7];
				
				assign WR0 = WRIN[4:0];
				assign WR1 = WRIN[4:0];
				assign WR2 = WRIN[4:0];
				assign WR3 = WRIN[4:0];
				assign WR4 = WRIN[4:0];
				assign WR5 = WRIN[4:0];
				assign WR6 = WRIN[4:0];
				assign WR7 = WRIN[4:0];
				assign WR8 = WRIN[4:0];
				assign WR9 = WRIN[4:0];
				assign WR10 = WRIN[4:0];
				// whatever. I need to make this configurable somehow.
				// for now I just want all the pins.
				assign WR11 = WRIN[9:5];
				
                wire srclk_internal;
				wire ss_incr_internal;
				wire sclk_internal;
				wire ramp_internal;
				IB u_srclk(.I(SRCLKIN),.O(srclk_internal));
				// The only thing that matters is RAMP's falling edge - so we
				// use it as an open-drain input so that it can function as both DONE
				// (driven by us) and RAMP (driven by FPGA).
				IBPU u_ramp(.I(RAMPIN),.O(ramp_internal));
				IB u_sclk(.I(SCLKIN),.O(sclk_internal));
				IB u_ss_incr(.I(SS_INCRIN),.O(ss_incr_internal));
				generate
                        genvar i;
                        for (i=0;i<12;i=i+1) begin : IBUF
                                ILVDS u_ilvds(.A(MONTIMING_P[i]),.AN(MONTIMING_N[i]),.Z(montiming_internal[i]));
								OLVDS u_olvds_srclk(.A(srclk_internal ^ SC_INVERT[i]),.Z(SRCLK_P[i]),.ZN(SRCLK_N[i]));
								// RAMP's inverted so it can idle high
								OB u_ob_ramp(.I(~ramp_internal),.O(RAMP[i]));
								OB u_ob_sclk(.I(sclk_internal),.O(SCLK[i]));
								OB u_ob_ss_incr(.I(ss_incr_internal),.O(SS_INCR[i]));														
                        end
                endgenerate

                wire montiming_muxed = montiming_internal[ctrl_sel];
                OLVDS u_olvds(.A(montiming_muxed),.Z(MONTIMINGOUT_P),.ZN(MONTIMINGOUT_N));

				assign LED = ctrl_sel;
endmodule
