    list p=16f877
    #include <p16f877.inc>
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF

; Declare variables
    cblock 0x20
        lcd_d1 ;Used for LCD_DELAY macro
        lcd_d2 ;Used for DELAY_5MS subroutine
        com ;For writing instruction to LCD
        table_counter ;Used for displaying characters on LCD
        dat ;For writing data to LCD
        COUNTH ;Used for DELAY_500MS subroutine
        COUNTM ;(see above)
        COUNTL ;(see above)
        comp_temp
    endc

    cblock 0x70
        KEY_PRESSED_ONE
        KEY_PRESSED_TWO
        CUR_SCREEN
    endc

; Declare constants for pin assignment (LCD on PORTD, see Lab 2 on Portal)
    #define	LCD_RS 	PORTD,2
	#define	LCD_E 	PORTD,3
    #define KEYPAD_P PORTB,1

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
    clrf CUR_SCREEN
    call CLEAR_KEYS
    call INITLCD
    goto REALTIME

;*************************************
; Main Program
;*************************************
REALTIME
    movlw b'00000000'
    movwf CUR_SCREEN
    call CLEAR_KEYS
    call CLEAR_LCD
    DISPLAY REALTIME_MESSAGE

    call SWITCH_LINES
    DISPLAY INPUT_LINE_CHAR
    goto KEYPAD_POLLING

NEW_OPERATION_DISPLAY
    call CLEAR_KEYS
    call CLEAR_LCD
    DISPLAY NEW_OPERATION_MESSAGE
    call USER_DELAY
    call SWITCH_LINES
    DISPLAY INPUT_LINE_CHAR
    goto KEYPAD_POLLING
NOS_3
    movlw b'00001000'
    movwf CUR_SCREEN
    call CLEAR_KEYS
    call CLEAR_LCD
    DISPLAY MAIN_MESSAGE_TWO
    call SWITCH_LINES
    DISPLAY INPUT_LINE_CHAR
    goto KEYPAD_POLLING
REPORT_DISPLAY
    call CLEAR_KEYS
    call CLEAR_LCD
    DISPLAY REPORT_MESSAGE
    call USER_DELAY
R_2
    movlw b'00000001'
    movwf CUR_SCREEN
    call CLEAR_KEYS
    call CLEAR_LCD
    DISPLAY OPERATION_TIME
    call SWITCH_LINES
    goto KEYPAD_POLLING
R_3
    call CLEAR_KEYS
    movlw b'00000010'
    movwf CUR_SCREEN
    call CLEAR_LCD
    DISPLAY INPUT_PATTERNS
    call SWITCH_LINES
    goto KEYPAD_POLLING

KEYPAD_POLLING
    call CLEAR_KEYS
    btfss KEYPAD_P ;Check if keypad is pressed
    goto $-1
    swapf PORTB,W     ;Read PortB<7:4> into W<3:0>, because KEYPAD pins corresponds to RB4-7
    andlw 0x0F

    call COMPARISON
    btfss KEY_PRESSED_TWO, 2 ;A
    goto $+2
    goto REALTIME
    btfss KEY_PRESSED_TWO, 3 ;B
    goto $+2
    goto NEW_OPERATION_DISPLAY
    btfss KEY_PRESSED_TWO, 4 ;C
    goto $+2
    goto REPORT_DISPLAY
    btfss KEY_PRESSED_ONE, 7
    goto $+2
    goto SCR_FORWARD
    btfss KEY_PRESSED_TWO, 0
    goto $+2
    goto SCR_BACKWARD
    goto NEXT
NEXT
    call KEYPAD_INPUT_CHARACTERS ;Convert keypad values to LCD display values
    call WR_DATA
    btfsc KEYPAD_P     ;Wait until key is released
    goto $-1
    goto KEYPAD_POLLING


SCR_FORWARD
    call CLEAR_KEYS
    btfss CUR_SCREEN, 3
    goto $+2
    goto NOS_2
    goto KEYPAD_POLLING
SCR_BACKWARD
    btfss CUR_SCREEN, 0
    goto $+2
    goto R_2
    btfss CUR_SCREEN, 1
    goto $+2
    goto R_3
    btfss CUR_SCREEN, 2
    goto $+2
    goto NOS_3
    goto KEYPAD_POLLING

    goto $

;***************************************
; Look up table
;***************************************
NEW_OPERATION_MESSAGE
		addwf	PCL,F
		dt		"New operation", 0

MAIN_MESSAGE_ONE
        addwf   PCL,F
        dt      "1st pattern: ", 0

MAIN_MESSAGE_TWO
        addwf   PCL,F
        dt      "2nd pattern: ", 0

REALTIME_MESSAGE
        addwf   PCL,F
        dt      "Real Time", 0

INPUT_LINE_CHAR
		addwf	PCL,F
		dt		">",0

REPORT_MESSAGE
        addwf   PCL, F
        dt      "Report", 0

KEYPAD_INPUT_CHARACTERS
        addwf   PCL,F
        dt      "123A456B789C*0#D", 0

OPERATION_TIME
        addwf   PCL, F
        dt      "Operation time: ", 0

INPUT_PATTERNS
        addwf   PCL, F
        dt      "Patterns: ", 0

ERR_MESSAGE
        addwf   PCL, F
        dt      "An Error Occurred", 0

;****************************************
; LCD Related Subroutines
;****************************************
INITLCD
    bcf STATUS, RP0
    bsf LCD_E
    call DELAY_5MS
    call DELAY_5MS
    call DELAY_5MS

    ;Ensure 8-bit mode first (no way to immediately guarantee 4-bit mode)
	; -> Send b'0011' 3 times
	movlw	b'00110011' ;Last two bits are don't cares
	call	WR_INST
	movlw	b'00110010'
	call	WR_INST
    ; 4 bits, 2 lines, 5x7 dots
	movlw	b'00101000'
	call	WR_INST
    ; display on/off
	movlw	b'00001111'
	call	WR_INST

	; Entry mode
	movlw	b'00000110' ;??
	call	WR_INST

	; Clear display
	movlw	b'00000001'
	call	WR_INST
	return
CLEAR_LCD
	movlw	B'00000001'
	call	WR_INST
    return
SWITCH_LINES
    movlw	B'11000000'
	call	WR_INST
	return
WR_INST
    bcf LCD_RS
    movwf com
    andlw 0xf0
    movwf PORTD
    bsf LCD_E
    call DELAY_5MS
    bcf LCD_E
    swapf com, W
    andlw 0xf0
    movwf PORTD
    bsf LCD_E
    call DELAY_5MS
    bcf LCD_E
    call DELAY_5MS
    return
WR_DATA
    bsf LCD_RS ;Exactly the same as bsf PORTD, 2. RS - Register selected
    movwf dat ;Creates a copy of W into dat
    ;movf dat, W ;?? Not sure why this line is needed, works without it
    andlw 0xf0 ;??
    addlw 4 ;?? Set RD2 to 1, and RD2 is RS. When RS is 1, you can write data to LCD, when RS is 0, you can write command it LCD
    movwf PORTD
    bsf LCD_E
    call DELAY_5MS
    swapf dat,W ;Swaps the lower half and upper half of dat and store in W
	andlw 0xF0
	addlw 4
	movwf PORTD
	bsf LCD_E
	call DELAY_5MS
	bcf LCD_E
	return

DELAY_5MS ;~5ms
    movlw d'20' ;20 seems to be arbitrary chosen. Less than 20 doesn't seem to work
    movwf lcd_d2
DELAY_5MS_LOOP
    LCD_DELAY
    decfsz lcd_d2,f ;Calls LCD_DELAY 20 times
    goto DELAY_5MS_LOOP
    return
DELAY_500MS
	local DELAY_500MS_0
    movlw 0x88
    movwf COUNTH
    movlw 0xBD
    movwf COUNTM
    movlw 0x03
    movwf COUNTL
DELAY_500MS_0
    decfsz COUNTH, f
    goto   $+2
    decfsz COUNTM, f
    goto   $+2
    decfsz COUNTL, f
    goto   DELAY_500MS_0
    goto $+1
    nop
    nop
    return
USER_DELAY
	local USER_DELAY_0
    movlw 0x88
    movwf COUNTH
    movlw 0xBD
    movwf COUNTM
    movlw 0x09
    movwf COUNTL
USER_DELAY_0
    decfsz COUNTH, f
    goto   $+2
    decfsz COUNTM, f
    goto   $+2
    decfsz COUNTL, f
    goto   USER_DELAY_0
    goto $+1
    nop
    nop
    return
COMPARISON
    movwf comp_temp
    btfsc comp_temp, 3
	goto THIRDNOTZERO
	btfsc comp_temp, 2
	goto SECONDNOTZERO_1
	btfsc comp_temp, 1
	goto FIRSTNOTZERO_3
	btfsc comp_temp, 0
	goto $+3
	bsf KEY_PRESSED_ONE, 1
	goto END_COMPARISON
	bsf KEY_PRESSED_ONE, 2
	goto END_COMPARISON
THIRDNOTZERO
	btfsc comp_temp, 2
	goto SECONDNOTZERO
	btfsc comp_temp, 1
	goto FIRSTNOTZERO_1
	btfsc comp_temp, 0
	goto $+3
	bsf KEY_PRESSED_ONE, 7
	goto END_COMPARISON
	bsf KEY_PRESSED_TWO, 0 ;8
	goto END_COMPARISON
SECONDNOTZERO_1
	btfsc comp_temp, 1
	goto FIRSTNOTZERO_2
	btfsc comp_temp, 0
	goto $+3
	bsf KEY_PRESSED_ONE, 4
	goto END_COMPARISON
	bsf KEY_PRESSED_ONE, 5
	goto END_COMPARISON
SECONDNOTZERO
	btfsc comp_temp, 1
	goto FIRSTNOTZERO
	btfsc comp_temp, 0
	goto $+3
	bsf KEY_PRESSED_TWO, 6
	goto END_COMPARISON
	bsf KEY_PRESSED_ONE, 0
	goto END_COMPARISON
FIRSTNOTZERO_3
	btfsc comp_temp, 0
	goto $+3
	bsf KEY_PRESSED_ONE, 3
	goto END_COMPARISON
	bsf KEY_PRESSED_TWO, 2 ;A
	goto END_COMPARISON
FIRSTNOTZERO_2
	btfsc comp_temp, 0
	goto $+3
	bsf KEY_PRESSED_ONE, 6
	goto END_COMPARISON
	bsf KEY_PRESSED_TWO, 3 ;B
	goto END_COMPARISON
FIRSTNOTZERO_1
	btfsc comp_temp, 0
	goto $+3
	bsf KEY_PRESSED_TWO, 1 ;9
	goto END_COMPARISON
	bsf KEY_PRESSED_TWO, 4 ;C
	goto END_COMPARISON
FIRSTNOTZERO
	btfsc comp_temp, 0
	goto ZEROTHNOTZERO
	bsf KEY_PRESSED_TWO, 7 ;#
	goto END_COMPARISON
ZEROTHNOTZERO
	bsf KEY_PRESSED_TWO, 5 ;D
	goto END_COMPARISON
END_COMPARISON
    return
CLEAR_KEYS
    clrf KEY_PRESSED_ONE
    clrf KEY_PRESSED_TWO
    return

    END
