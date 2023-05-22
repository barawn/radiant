#include <stdio.h>

#include "Si5338-RevB_RADIANT_INTERNAL-Registers_2.h"

int main() {
	for (int i=0;i<NUM_REGS_MAX;i++) {
		if (Reg_Store[i].Reg_Mask != 0x00)
			printf("%2.2x%2.2x%2.2x\n", Reg_Store[i].Reg_Addr, Reg_Store[i].Reg_Val, Reg_Store[i].Reg_Mask);		
	}
}
