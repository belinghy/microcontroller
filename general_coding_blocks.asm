;*******************************************
; Must have for programming in MPLAB IDE
; __CONFIG writes to the configuration of PIC (Text P. 7-25)
;*******************************************
	list p=16f877
    #include "p16f877.inc"
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF
	

;*******************************************
; Declaring Variables (unbanked)
;*******************************************
	cblock 0x20 ;Allocate a block, 0x20 indicates address in memory
		<VARIABLE_NAME_1>
		<VARIABLE_NAME_2>
		...
	endc
	
	
;*******************************************
; Program Reset
;*******************************************
	org 0x0000	;0x0000 indicates program start address
	goto <LABEL_NAME> ;usually goto MAIN
	
	
;***************************************************
;	Using Interrupt
;   btfsc INTCON, INTF ---> If INTCON<INTF> is 1, then execute next instruction.
;                         Else, discard next instruction and execute NOP.
;   bcf INTCON, INTF ---> Set INTCON<INTF> to 0
;   INTCON is a special register, use for RB0/INT (pin 33) interrupt
;   INTF is the "flag bit" of INTCON, is set to 1 when interrupt in RB0/INT occurs
;***************************************************
    btfsc INTCON, INTF
    call ISR_Lit
    bcf INTCON, INTF
	
	
;***********************************************************
; Setting Macro
;	When macro is called, the program simply replaces the code wherever it is called
;***********************************************************
<MACRO_NAME> macro [PARAMETER1, PARAMETER2, ...]
	<inst.>
	<inst.>
	...
	endm
	
;****************************************
; Write command to LCD - Input : W , output : -
; (Text P. 7-104)
;****************************************
WR_INST
    bcf RS
    movwf com
    andlw 0xf0
    movwf PORTD
    bsf E
    call LCDLONGDELAY
    bcf E
    swapf com, W
    andlw 0xf0
    movwf PORTD
    bsf E
    call LCDLONGDELAY
    bcf E
    call LCDLONGDELAY
    return

;****************************************
; Write data to LCD - Input : W , output : -
;****************************************
WR_DATA
    bsf RS ;Exactly the same as bsf PORTD, 2. RS - Register selected
    movwf dat ;Creates a copy of W into dat
    ;movf dat, W ;?? Not sure why this line is needed, works without it
    andlw 0xf0 ;??
    addlw 4 ;?? Set RD2 to 1, and RD2 is RS. When RS is 1, you can write data to LCD, when RS is 0, you can write command it LCD
    movwf PORTD
    bsf E
    call LCDLONGDELAY
    swapf dat,W ;Swaps the lower half and upper half of dat and store in W
	andlw 0xF0
	addlw 4
	movwf PORTD
	bsf E
	call LCDLONGDELAY
	bcf E
	return