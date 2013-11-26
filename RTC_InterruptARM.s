Initialize GPIO <67> for output
CLEAR GPIO<<67> to low
ENABLE the RTSR enable the alarm interrupt 
HOOK the IRQ procedure INSTALL the int_procedure
RESET RTNR to 0
INITIALISE the interrupt
	
CLEAR CPSR to turn on the interrupt
SET and interrupt to enter the WAIT LOOP for first time
Start WAIT LOOP

CALL INT_DIRECTOR LOOP
	CALL the STACK 
	CHECK THE STATUS OF INTERRUPT ICIP
	IF alarm interrupt is asserted 
		IF LED is turned OFF 
			REENABLE the alarm interrupt 
			TURN ON
			RTAR is set to 5 sec
			RESET RTNR to 0
		RETURN TO WAIT LOOP 
		IF LED is ON 
			REENABLE the alarm interrupt 
			TURN OFF 
			RTAR is set to 2 sec
			RESET RTNR to 0 
			RETURN TO WAIT LOOP
	ELSE 
		GO to BOOTLOADER IRQ perform the necessary procedure
	RETURN to WAIT LOOP

4. Results and Analysis


.S file


@Tenzin Ngodup ECE 371 Project1
@portland state university
@11/23/2012
@PROJECT 3

@Using the Real-Time Clock on an Interrupt Basis 
@interrupt service is connected to RTSR where Real time CLock interrupt is enabled
@

.text
.global _start
_start:
@initialize

.EQU GPLR0, 0x40E00000
.EQU GPLR2, 0x40E00008
.EQU GPDR2, 0x40E00014
.EQU GPSR2, 0x40E00020
.EQU GPCR2, 0x40E0002C
.EQU GAFR2_L, 0x40E00064
	LDR R0,=GPLR0      @set up for GPLR2 on R0 
	LDR R1,=GPDR2       @set up  for GPDR2 on R1
	LDR R2,=GPSR2       @set up for GPSR2 on R2
	LDR R3,=GPCR2      @set up for GPCR2 on R3
	LDR R4,=GAFR2_L     @set up for GAFR2_L  on R4
@cLearing the alternate function of GPIO<67> to 00	
	LDR R8,=0xFFFFFF3F 	@WORD TO CLEAR the pin 67 for alternate function 
	LDR R6,[R4]            @READ GAFR2_L TO GET CURRENT VALUE 
 	AND R8,R8,R6           @MODIFY SET BIT 7-6 TO PROGRAM GPIO 67 
 	STR R8,[R4]             @WRITE BACK TO GAFR2_L
@setting GPCR to 1 to clear output to GPIO<67> 
   	LDR R7,=0x8             @ to clear pin 67 for GPCR for output
	STR R7,[R3]             @ to clear GPCR2 at pin 67
@setting GPDR to 1 to enable output for GPIO<67> 
	LDR R6,[R1]                @gets the GPDR2
	ORR R6,R6,R7               @Set 1 to bit 4 to program GPIO 67 for output     
	STR R6,[R1] 
	
@SET Oscillator controller to use 32.768 KHz Oscillator
	LDR R0, =0x41300008   @Address of oscillator configuration reg
	LDR R1,[R0]               @load current value
	ORR R1,R1,#02           @set 1 to enable change to 32.678HZ
	STR R1,[R0]            @WRITE back to OSCC register 
@enable RTC Alarm interrupt  in real time clock
	LDR R0, =0x40900008       @pointer to RTC register(RTSR)
	LDR R1,[R0]            @read the status of register
	MOV R2,#0x04           @mask to set bit 2
	ORR R1,R1,R2     @set bit 2
	STR R1,[R0]       @write back to status register
@initialize interrupt controller 
@default value of IRQ for IRQ for ICLR bits 31,10 is desired value, so change
@default value of DIM bit in ICCR is desired value, so no word sent
	LDR R0, = 0x40D00004         @load address of ICMR register
	LDR R1,[R0]                  @Read the value of register
	LDR R2,=0x80000400            @load the value to unmask bit 30 for RTC seconds and 10 for GPIO 
	ORR R1,R1,R2               @set bit to unmask IM31 and IM10
	STR R1,[R0]               @write back to ICMR register
@HOOK IRQ procedure address and install our int_handler address
	MOV R1,#0x18		@load IRQ interrupt vector address 0x18
	LDR R2,[R1]                @read instr from interrupt vector table at 0x18
	LDR R3,=0xFFF            @contruct mask 
	AND R2,R2,R3              @mask all but offset part of instruction 
	ADD R2,R2,#0x20           @absoblute addreass of irq procedure in literal pool 

	LDR R3,[R2]
	STR R3,BTLDR_IRQ_ADDRESS        @save the address of IRQ address for use in IRQ_DIRECTOR 
	LDR R0,=INT_DIRECTOR         @load the absolute address of our interrupt director 
	STR R0,[R2]                      @store this address in literal_pool. for IRQ 
@Make sure interrupt on processor enabled by clearing bit 7 in cpsr
	MRS R3,CPSR                     @COPY CPSR to R3
	BIC R3,R3,#0x80                 @Clear bit 7 to enable IRQ interrupt
	MSR CPSR_c,R3             @write back to lowest 8bit  of CPSR
	
@making sure to clear the output on GPCR by setting 1(TURN OFF THE LED to make sure) 
	LDR R7,=GPCR2            @LOAD PINTER TO GPCR2
	LDR R4,[R7]              @load the value to R4
	MOV R4, #0x00000008        @bit 3 to mask on  
	STR R4,[R7]                @store the value back to GPCR2 
@reset RCNR to reset the clock for interrupt
	LDR R3,=0x40900000        @load the address of RCNR 
	LDR R4,[R3]                 @read the status of RCNR 
	MOV R4,#0x00000000          @Clear RCNR counter to 0 
	STR R4,[R3]  
@set the RTAR to 1 sec so that interupt is produced after 1 sec                
	LDR R1,=0x40900004      @load the address of RTAR
	MOV R2,#0x1              @write 1 bit to produce interrupt after 1 sec
	STR R2,[R1]                 @write back to register
	



LOOP: 	NOP                      @wait loop 
	B LOOP


INT_DIRECTOR:                       @chain button interupt procedure 
	STMFD SP!,{R0-R3,LR}        @saved register to use for stack 
	LDR R0,= 0x40D00000   @Check bit 31 at ICIP for IRQ Pending Register at 
	LDR R1,[R0]             @
	TST R1,#0x80000000     @ Check IRQ interupt due to bit<31> 
	BNE SEC_CNT 
	TST R1,#0x400
	BEQ PASSON
	LDMFD R13!,{R0-R3,LR}
	SUBS PC,LR,#4
	

PASSON: LDMFD SP!,{R0-R3,LR}
	LDR PC,BTLDR_IRQ_ADDRESS

SEC_CNT:
	LDR R0, =0x40900008   @test the RTSR  bit 0 
	LDR R2,[R0]
	TST R2,#0x0
	BEQ IRT
	MOV PC,LR
IRT:	LDR R7,=GPLR2  @LOAD PINTER TO GPSR2
	LDR R3,[R7]
	TST R3,#0x8
	BNE TWO
	BEQ FIVE

FIVE:	LDR R0, =0x40900008   @Clear RTSR
	LDR R1,[R0]
	MOV R2,#0x0b1
	STR R2,[R0] 
	LDR R2,[R0]             
	MOV R2,#0x4            @reenable alarm bit 2 RTSR   
	STR R2,[R0]
	
	LDR R7,=GPSR2  @LOAD PINTER TO GPSR2
	LDR R4,[R7]
	MOV R4, #0x00000008
	STR R4,[R7]

	LDR R3,= 0x40900000        @ Clear RCNR counter to 0 
	LDR R4,[R3]
	AND R4,#0x00000000
	STR R4,[R3] 
	LDR R1,=0x40900004      @ Check the RTAR
	MOV R2,#0x5
	STR R2,[R1]
	
	LDMFD SP!,{R0-R3,LR}
	SUBS PC,LR,#4

TWO:	
	LDR R0, =0x40900008   @Clear RTSR
	LDR R1,[R0]
	MOV R2,#0x0b1
	STR R2,[R0] 
	LDR R2,[R0]             
	MOV R2,#0x4            @reenable alarm bit 2 RTSR   
	STR R2,[R0]
	
	LDR R7,=GPCR2  @LOAD PINTER TO GPSR2
	LDR R4,[R7]
	MOV R4, #0x00000008
	STR R4,[R7]

	LDR R3,= 0x40900000        @ Clear RCNR counter to 0 
	LDR R4,[R3]
	AND R4,#0x00000000
	STR R4,[R3] 
	LDR R1,=0x40900004      @ Check the RTAR
	MOV R2,#0x2
	STR R2,[R1]

	 
	LDMFD SP!,{R0-R3,LR}
	SUBS PC,LR,#4


	
BTLDR_IRQ_ADDRESS: .word 0





.end
