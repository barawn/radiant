# RADIANT clock configuration

The RADIANT board's main clock is 1/128th the sample clock,
which is configured by the board manager at startup.

It can either be built from a 10 MHz internal clock (IN3) or an
external clock (IN1/2 as a differential input).

There is a feedback path (CLK3A routed to IN4) which is available
IF the RADIANT has an N/P/Q device installed which provides a zero-delay
mode. This obviously only makes sense for the external clock.

This can be determined at runtime by reading Dev_Config3[3:0] in
register 3 (see pp53-56 in the Si5338 family reference manual).

The board manager configures the clock from a simplified register
file in the CircuitPython drive. This register file consists of
a single value (in hex) containing of the register, its value,
and its mask. You can generate this file by exporting the configuration
from ClockBuilderPro as a C header and running something like
generateClockFile.c.

Right now the board manager only loads a file named "intclock25.dat".
It probably makes sense to have a way for it to load from differently
named files (and also create new ones!). Alternatively, the board manager
could have functions for writing the registers directly.

The ClockBuilderPro project in this directory should give a good starting point.