    list p=16f877
    #include "p16f877.inc"
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF


    cblock 0x20 ;Allocate space for variables
        temp_w
        temp_status
    endc

    org 0x0000  ;Program starts at address zero
    goto MAIN

    org 0x0004
    movwf temp_w    ;(W) -> (temp_w), store w/e is inside W into temp_w
    movf STATUS, W  ;move STATUS into W
    movwf temp_status ;store STATUS register into temp_status

;***************************************************
;   btfsc INTCON, INTF ---> If INTCON<INTF> is 1, then execute next instruction.
;                         Else, discard next instruction and execute NOP.
;   bcf INTCON, INTF ---> Set INTCON<INTF> to 0
;   INTCON is a special register, use for RB0/INT (pin 33) interrupt
;   INTF is the "flag bit" of INTCON, is set to 1 when interrupt in RB0/INT occurs
;***************************************************
    btfsc INTCON, INTF
    call ISR_Lit
    bcf INTCON, INTF

;Reset previously stored registers
    movf temp_status, W
    movwf STATUS
    movf temp_w, W
    retfie  ;return from interrupt

MAIN
    call init
    call ISR_init
    call ADinit
    goto $

ADinit
    bsf STATUS, RP0 ;SET STATUS<RP0> to 1, select bank1
    movlw 0x07 ;Set RE2-0 and RA5-0 to digital input (Datasheet P.114)
    movwf ADCON1 ;ADCON1 is used for analog vs. digital input configuration
    bcf STATUS, RP0 ;select bank0 again
    return

init
    bsf STATUS, RP0
    clrf TRISD ;Write 0x00 to TRISD
    clrf TRISA
    movlw   b'00000001'
	movwf   TRISB
	clrf	TRISC
	movlw 	b'00000001'
	movwf	TRISE

    bcf		STATUS,RP0	;bank0
	clrf	PORTA		;clear all ports
	clrf	PORTB
	clrf	PORTC
	clrf	PORTD
	clrf	PORTE
    return

ISR_init
	bcf 	STATUS,RP0
	bcf 	INTCON,INTF
	bsf 	INTCON,GIE ; Enable interrupt globally
	bsf		INTCON,INTE ; Enable RB0/INT interrupt
	return

ISR_Lit

	call clear_LED
	btfsc PORTE,0		;if PORTE 0 selected
	goto _Show1			;goto pattern 1
	call Pattern_ZERO	;else display pattern 0
	return

_Show1
	call Pattern_ONE	;display pattern 1
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Pattern_ONE
	movlw b'00100100'
	movwf PORTB
	movlw b'01111100'
	movwf PORTC
	bsf PORTD,2
    return

Pattern_ZERO

	movlw b'01111100'
	movwf PORTB
	movlw b'01000100'
	movwf PORTC
	movlw b'01111100'
	movwf PORTD
    return

clear_LED
	clrf PORTB
	clrf PORTC
	clrf PORTD
    return

END