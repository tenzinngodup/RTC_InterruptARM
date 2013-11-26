USING A REAL-TIME CLOCK ON AN INTERRUPT BASIS 

1. Introduction
The interrupt service based on real time clock is used for this project. The RTSR is used to enable the RTC alarm on Bit 2. Since we can enable the processor to produce a interrupt when RTNR is equal to RTAR. 
2. Theory or Background
The ARM processor has a function where interrupt can be produced at a desired time. This function  is located RTNR clock such that interrupt is produced every second. This is when enabled such that is equal to RTAR is equal to RTNR a alarm interrupt is produced . 
			RTAR = RTNR -> alarm interrupt 

Therefore, we enter the loop, and when the above situation happens we interrupt is produced and we exit the loop. We then reclock the time and enable the alarm again. 
