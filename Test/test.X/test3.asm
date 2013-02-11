; for LCD series 162A
	#include <p16f877.inc>
	#include <common.inc>
	extern delay50us, delay5ms, delayX5msm, delay1sl
	;Only these functions are visible to other asm files
	global LCD_init, LCD_clear, LCD_line2, LCD_out, LCD_wt
	;Declare unbanked variables (at 0x70 and on)
	UDATA_SHR
lcd_tmp res 1
;*******************************************************************************
; "ClkLCD": LCD Enable Click Function
; Func: Pulse the E line low
; Input: None
; Output: None
; Affect: STATUS, delaytemp, delaycount
; Runtime: 102.4 us
;*******************************************************************************
ClkLCD macro
	call delay50us
	bcf LCD_E
	call delay50us
	bsf LCD_E
endm
;*******************************************************************************
; "MovMSB": Most Significant Bits Move Function
; Func: Move MSB of W to LCD_PORT<4:7>, without disturbing LSB
; Input: W
; Output: LCD_PORT
; Affect: STATUS
; Runtime: 3.2 us
;*******************************************************************************
MovMSB macro
	andlw 0xF0
	iorwf LCD_PORT,f
	iorlw 0x0F
	andwf LCD_PORT,f
	endm

	code
;*******************************************************************************
; "LCD_init": LCD Initialization Function
; Func: Initialize LCD after reset
; Input: None
; Output: None
; Affect: delaytemp, delaycount, delaytemp2, delaycount2,
; Runtime: 37,074.8 us
;*******************************************************************************
LCD_init
	BANK0
	bsf LCD_E ; E default high
	; Wait for more than 15ms after VDD rises to 4.5V (20ms)
	call delay5ms
	call delay5ms
	call delay5ms
	call delay5ms
	;Ensure 8-bit mode first (no way to immediately guarantee 4-bit mode)
	 ; -> Send b'0011' 3 times
	bcf LCD_RS ; Instruction mode
	movlw B'00110000'
	MovMSB
	; Finish last 4-bit send (if reset occurred in middle of a send)
	ClkLCD
	call delay5ms ; Wait for more than max instruction time 4.1ms(5ms)
	ClkLCD ; Assuming 4-bit mode, set 8-bit mode
	call delay50us ; Wait for more than 100us
	call delay50us
	ClkLCD
	; (note: if it's in 8-bit mode already, it will stay in 8-bit mode)
	; Now that we know for sure it's in 8-bit mode, set 4-bit mode.
	movlw B'00100000'
	MovMSB
	ClkLCD
	; Give LCD init instructions
	movlw B'00101000' ; 4 bits, 2 lines,5X8 dot
	call LCD_wt
	movlw B'00001111' ; display on,cursor,blink
	call LCD_wt
	movlw B'00000110' ; Increment,no shift
	call LCD_wt
	; Ready to display characters
	call LCD_clear
	bsf LCD_RS ; Character mode
	return
;*******************************************************************************
; "LCD_clear": LCD Clear Function
; Func: Clear the LCD display using clear command
; Input: None
; Output: None
; Affect: W, STATUS, delaytemp, delaycount, lcd_temp
; Runtime: 2,264.8 us
;*******************************************************************************
LCD_clear
	bcf LCD_RS ;Instruction mode
	movlw B'00000001'
	call LCD_wt
	; expected excution time: 1.64ms (~2ms)
	movlw .40
	movwf lcd_tmp
	call delay50us
	decfsz lcd_tmp, f
	goto $-2
	bsf LCD_RS ; Character mode
	return
;*******************************************************************************
; "LCD_line2": LCD Move to Seocnd Line Function
; Func: Move the LCD cursor to second Line
; Input: None
; Output: None
; Affect: W, STATUS, delaytemp, delaycount
; Runtime: 216.4 us
;*******************************************************************************
LCD_line2
	bcf LCD_RS ; Instruction mode
	movlw B'11000000' ; shift position to 40h : second line
	call LCD_wt
	bsf LCD_RS ; Character mode
	return
;*******************************************************************************
; "LCD_out": LCD Move Out of Screen Function
; Func: Move the LCD cursor out of screen (to 50h)
; Input: None
; Output: None
; Affect: W, STATUS, delaytemp, delaycount
; Runtime: 216.4 us
;*******************************************************************************
LCD_out
	bcf LCD_RS ; Instruction mode
	movlw B'11010000' ; shift position to 50h : out of screen
	call LCD_wt
	bsf LCD_RS ; Character mode
	return
;*******************************************************************************
; "LCD_wt": LCD Write Function
; Func: Clock MSB and LSB of W to LCD_PORT<7:4> in two cycles
; Input: W
; Output: None
; Affect: W, STATUS, delaytemp, delaycount
; Runtime: 213.6 us
;*******************************************************************************
LCD_wt
	movwf lcd_tmp ; store original value
	MovMSB ; move MSB to PORTD
	ClkLCD
	swapf lcd_tmp,w ; Swap LSB of value into MSB of W
	MovMSB ; move to PORTD
	ClkLCD
	return
	end