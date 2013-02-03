    list p=16f877
    #include <p16f877.inc>
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF

; Declare variables
    cblock 0x70
        lcd_d1
        lcd_d2
        com
        table_counter
        dat
    endc

; Declare constants for pin assignment (LCD on PORTD, see Lab 2 on Portal)
    #define	RS 	PORTD,2
	#define	E 	PORTD,3

    ORG 0x0000
    goto MAIN_INIT

;***************************
;   Delay: 160ms
;***************************
LCD_DELAY macro
    movlw 0xff
    movwf lcd_d1
    decfsz lcd_d1, f ; Decrement lcd_d1, if lcd_d1 = 0, then discard next instruction
    goto $-1
    endm

;***************************
;   Display Macro
;***************************
DISPLAY macro MESSAGE
    local D_LOOP
    local D_END
    clrf table_counter
    clrw
D_LOOP
    movf table_counter, W
    call MESSAGE ;??
    xorlw B'00000000' ;used to change STATUS<Z>, if result is 0, then Z=1
    btfsc STATUS, Z ; if STATUS<Z> is 1, execute next inst. Else, discard next inst.
        goto D_END
    call WR_DATA ;??
    incf table_counter, F
    goto D_LOOP
D_END
    endm

;***************************************
; Initialize LCD
;***************************************
MAIN_INIT
    clrf INTCON ; No interrupt
    bsf STATUS, RP0
    clrf TRISA
    movlw b'11110010' ;Set required keypad inputs (PORTB is KEYPAD)
    movwf TRISB
    clrf TRISC ;All port C is output
    clrf TRISD ;All port D is output (PORTD is LCD)

    bcf STATUS, RP0 ;Select bank 0
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    call INITLCD

;*************************************
; Main Program
;*************************************
MAIN
    DISPLAY WELCOME_MESSAGE

    call SWITCH_LINES
    DISPLAY ALPHABET

    goto $

;***************************************
; Look up table
;***************************************

WELCOME_MESSAGE
		addwf	PCL,F
		dt		"Testing!", 0

ALPHABET
		addwf	PCL,F
		dt		"Testing Two",0

;****************************************
; LCD Related Subroutines
;****************************************
INITLCD
    bcf STATUS, RP0
    bsf E
    call LCDLONGDELAY
    call LCDLONGDELAY
    call LCDLONGDELAY

    ;Ensure 8-bit mode first (no way to immediately guarantee 4-bit mode)
	; -> Send b'0011' 3 times
	movlw	b'00110011'
	call	WR_INST
	movlw	b'00110010'
	call	WR_INST

    ; 4 bits, 2 lines, 5x7 dots
	movlw	b'00101000'
	call	WR_INST

    ; display on/off
	movlw	b'00001100'
	call	WR_INST

	; Entry mode
	movlw	b'00000110' ;??
	call	WR_INST

	; Clear display
	movlw	b'00000001'
	call	WR_INST
	return

;************************************
; LCD CONTROL
;************************************
CLEAR_LCD
	movlw	B'00000001'
	call	WR_INST
    return

SWITCH_LINES
    movlw	B'11000000'
	call	WR_INST
	return

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

LCDLONGDELAY ;~5ms
    movlw d'20' ;20 seems to be arbitrary chosen. Less than 20 doesn't seem to work
    movwf lcd_d2
LLD_LOOP
    LCD_DELAY
    decfsz lcd_d2,f ;Calls LCD_DELAY 20 times
    goto LLD_LOOP
    return

    END