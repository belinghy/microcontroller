    list P=PIC16F877, F=INHX8M, C=160, N=80, ST=OFF, MM=OFF, R=DEC
	include "P16F877.INC"
	__config ( _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF )
	errorlevel -302		;ignore error when storing to bank1


	org 0x0000
 	goto	Mainline


	org 0x0004
	movwf 	temp_w
	movf 	STATUS,w
	movwf  	temp_status

	btfsc 	INTCON,INTF
	call	ISR_Lit
	bcf 	INTCON,INTF

	movf 	temp_status
	movwf 	STATUS
	swapf	temp_w,f
	swapf	temp_w,w
	retfie


	cblock 0x20
	temp_w
	temp_status

	endc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline

	call init
	call ISR_init
	call ADinit

goto	$

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ADinit 					;digital input initiation
	bsf 	STATUS,RP0	;bank1
	movlw	0x07
	movwf	ADCON1		;set to digital input
	bcf 	STATUS,RP0	;bank0
	return



init					;select port function
	bsf		STATUS,RP0	;bank1
	clrf	TRISD		;set ALL to inputs
	clrf	TRISA
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



ISR_init

	bcf 	STATUS,RP0
	bcf 	INTCON,INTF
	bsf 	INTCON,GIE
	bsf		INTCON,INTE

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