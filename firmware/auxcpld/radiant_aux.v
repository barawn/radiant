module radiant_aux(
        input CTRL_CLK,
        input CTRL_DATA,
        input [11:0] MONTIMING_P,
        input [11:0] MONTIMING_N,
        output MONTIMINGOUT_P,
        output MONTIMINGOUT_N,
        input SRCLKIN,
		input RAMPIN,
		inout SS_INCRIN,
		input SCLKIN,
		output [11:0] SCLK,
		inout  [11:0] SS_INCR,		
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

	// This maps 9-11 and 21-23 to the "high" WR bits.
	// Because 12-20 are the surface channels, this means
	// low left = deep
	// high left = deep
	// low right = surface
	// high right = deep
	parameter [11:0] WR_MAP =    12'b111000000000;

                reg [7:0] ctrl_sel = {8{1'b0}};
                always @(posedge CTRL_CLK) ctrl_sel <= {CTRL_DATA, ctrl_sel[7:1]};

                wire [15:0] montiming_internal;
				assign montiming_internal[12] = montiming_internal[4];
				assign montiming_internal[13] = montiming_internal[5];
				assign montiming_internal[14] = montiming_internal[6];
				assign montiming_internal[15] = montiming_internal[7];
				
				// this is AMAZING AMOUNTS OF SLEAZE
				// In BIST mode, we want every non-selected monitor to be set to '4' (passthrough),
				// or 100. The selected monitor gets its values picked off from ctrl_sel[6:4].
				// We also don't want to screw with the timing here and run the WR guys
				// through muxes or anything. So how do we do it? Easy: it's static! In BIST mode
				// the LAB4 controller isn't running, so we tristate the WRs.
				
				wire [4:0] analog_sel = { 2'b00, ctrl_sel[6:4] };
				wire [4:0] analog_passthrough = 5'b00100;
				// Not a big fan of this, will probably change this to JTAG control so that in normal
				// operation (including MONTIMING mux) BIST isn't accidentally activated.
				wire bist = ctrl_sel[7];

				wire [4:0] wr_out[11:0];
								
				wire [4:0] wr_low;
				wire [4:0] wr_high;
								
				assign WR0 = wr_out[0];
				assign WR1 = wr_out[1];
				assign WR2 = wr_out[2];
				assign WR3 = wr_out[3];
				assign WR4 = wr_out[4];
				assign WR5 = wr_out[5];
				assign WR6 = wr_out[6];
				assign WR7 = wr_out[7];
				assign WR8 = wr_out[8];
				assign WR9 = wr_out[9];
				assign WR10 = wr_out[10];
				assign WR11 = wr_out[11];
				
                wire srclk_internal;
				wire ss_incr_internal;
				wire [15:0] shout_internal;
				assign shout_internal[15:12] = shout_internal[7:4];
				wire sclk_internal;
				wire ramp_internal;
				IB u_srclk(.I(SRCLKIN),.O(srclk_internal));
				// The only thing that matters is RAMP's falling edge - so we
				// use it as an open-drain input so that it can function as both DONE
				// (driven by us) and RAMP (driven by FPGA).
				IBPU u_ramp(.I(RAMPIN),.O(ramp_internal));
				IB u_sclk(.I(SCLKIN),.O(sclk_internal));
				// drive SS_INCRIN only if we're in BIST: meaning T=0 if bist=1
				BB u_ssincr(.I(shout_internal[ctrl_sel[3:0]]),
							.O(ss_incr_internal),
							.T(!bist),
							.B(SS_INCRIN));
				generate
                        genvar i,j,k;
						for (k=0;k<5;k=k+1) begin : WRIN_LOOP
							IB u_wrlow(.I(WRIN[k]),.O(wr_low[k]));
							IB u_wrhigh(.I(WRIN[5+k]),.O(wr_high[k]));
						end
                        for (i=0;i<12;i=i+1) begin : IBUF
							wire [3:0] this_lab = i;
							wire my_montiming;
							wire select_this_lab = (ctrl_sel[3:0] == this_lab);
							wire [5:0] debug_tris = (select_this_lab) ? analog_sel : analog_passthrough;							
							if (WR_MAP[i]) begin : HIGHWR
								for (j=0;j<5;j=j+1) begin : HWRL
									OBZPU u_wr(.I(wr_high[j]),.T(debug_tris[j] && bist),.O(wr_out[i][j]));
								end
							end else begin : LOWWR
								for (j=0;j<5;j=j+1) begin : LWRL
									OBZPU u_wr(.I(wr_low[j]),.T(debug_tris[j] && bist),.O(wr_out[i][j]));
								end
							end
							ILVDS u_ilvds(.A(MONTIMING_P[i]),.AN(MONTIMING_N[i]),.Z(my_montiming));
							assign montiming_internal[i] = my_montiming ^ MT_INVERT[i];							
							OLVDS u_olvds_srclk(.A(srclk_internal ^ SC_INVERT[i]),.Z(SRCLK_P[i]),.ZN(SRCLK_N[i]));
							// RAMP's inverted so it can idle high
							OB u_ob_ramp(.I(~ramp_internal),.O(RAMP[i]));								
							OB u_ob_sclk(.I(sclk_internal),.O(SCLK[i]));
							// SS_INCR also acts as SHOUT in BIST mode.
							// They have to have pullups on them because the cheat circuit can only pull down.
							// Tristate all SS_INCRs in BIST mode.
							BBPU u_ss_incr(.I(ss_incr_internal),
										   .O(shout_internal[i]),
										   .T(bist),
										   .B(SS_INCR[i]));
                        end
                endgenerate

                wire montiming_muxed = montiming_internal[ctrl_sel[3:0]];
                OLVDS u_olvds(.A(montiming_muxed),.Z(MONTIMINGOUT_P),.ZN(MONTIMINGOUT_N));

				assign LED = ctrl_sel[7] ? ctrl_sel[7:4] : ctrl_sel[3:0];
endmodule
