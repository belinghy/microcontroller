	list p=16f877 ; list directive to define processor
	#include <p16f877.inc> ; processor specific variable definitions
	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF
	#include <common.inc>
	extern LCD_init, LCD_clear, LCD_line2, LCD_out, LCD_wt
	extern delay50us, delay5ms, delayX5msm, delay100ms, delayX100msm, delay1sl
;******************VARIABLES****************************************************
	cblock 0x20
		phase ; 0 = realtime, 1 = report, 2 = run
		report_num
		line_num
		LCDline : .17 ; 16 + null
		temp ; only local use: must be discard before calling/jumping
		temp2
		temp3
		temp4
		temp5
		temp6
		temp7
		arg ; argument
		arg2
		literal_addr
		rowleft ; how many rows left to inspect
		result_addr ; adress to store result of current row in "layout"
		rt_year ; realtime
		rt_month
		rt_day
		rt_hour
		rt_min
		rt_sec
		st_year ; start
		st_month
		st_day
		st_hour
		st_min
		st_sec
		end_hour
		end_min
		end_sec
		runtime
		cl_total
		cl_pass
		cl_fail
		layout : .20 ; result
		smotor_dir ; direction of stepper motor
		log_total ; total numbers of reports available
		log_next ; index of where next report will be written
		arith_temp ; arithmetic temp
		arith_temp2
		newsec ; a new second occur (Bool from interrupt)
	endc
	cblock 0xB0
		light_bg : 5 ; background light intensity of current row
		light_pos : 5 ; position reflected light intensity of current row
		light_cl : 5 ; closet light LEDs light intensity of current row
		light_off : 5 ; closet light off light intensity of current row
	endc

	udata_shr
w_temp res 1
status_temp res 1
;pclath_temp res 1
FSR_temp res 1
rt_counter res 1 ; real time counter
table_temp res 1

;******************MACROS*******************************************************
DIVLW macro L
	movwf arith_temp
	movlw L
	call divfn
endm

MODLW macro L
	movwf arith_temp
	movlw L
	call divfn
	movf arith_temp, w
endm

MULLW macro L
	movwf arith_temp
	movlw L
	call mulfn
endm

COPY_STRING macro string_table
	movlw string_table
	call copystring
endm

COPY_LAYOUT macro rownum
	movlw rownum
	call copylayout
endm

COPY_DEC1 macro decnumber
	movf decnumber, w
	movwf arg
	movlw 0x01
	movwf arg2
	call copydec
endm

COPY_DEC2 macro decnumber
	movf decnumber, w
	movwf arg
	movlw 0x02
	movwf arg2
	call copydec
endm

COPY_DEC3 macro decnumber
	movf decnumber, w
	movwf arg
	movlw 0x03
	movwf arg2
	call copydec
endm

TABLE macro
	local tablename
	movwf table_temp
	movlw HIGH tablename
	movwf PCLATH
	movf table_temp, w
	addlw LOW tablename
	btfsc STATUS, C
	incf PCLATH, f
	movwf PCL
	tablename
endm

STORE_LIGHT macro addr
	movlw addr
	call lightsensor
endm

IRLED_ON macro
	movlw 0x01
	call ledcontrol
endm

IRLED_OFF macro
	movlw 0x00
	call ledcontrol
endm

CALC_POS macro threshold
	movwf temp
	movlw threshold
	movwf temp4
	call calcpos
endm

PRINT_DOT macro
	MOVLF FSR, LCDline
	COPY_STRING str_dot
	call writeline
endm
;*******************************************************************************
;*******************************************************************************
	org 0x0000
	#IFNDEF DEBUG
	goto main
	#ELSE
	goto mac_test
	#ENDIF
	#IFNDEF DEBUG
	org 0x0004
	goto interrupt
	#ENDIF
;*******************************************************************************
; "literal": String Literal Function
; Func: Store all string literal in this project here, it return
; any char wanted
; Input: W = the program memory address of the wanted char
; Output: W = the corresponding char
;*******************************************************************************
	org 0x0005 ; make sure literal table is in first 256 lines
literal
	movwf temp
	clrf PCLATH
	movf temp, w
	movwf PCL
	; max length 16 dt "0123456789ABCDEF", 0
str_init dt "INITIALIZING...", 0
str_noreport dt "NO REPORT", 0
str_enterymd dt "ENTER 20YYMMDD:",0
str_enterhms dt "ENTER hhmmss:", 0
str_yearhead dt "20", 0 ; all years like 20XX
str_dash dt "-", 0
str_colon dt ":", 0
str_entry dt "LOG ENTRY: ",0
str_start dt "START: ", 0
str_finish dt "FINISH: ", 0
str_runtime dt "RUNTIME: ", 0
str_s dt "s", 0 ; i.e. second
str_total dt "TOTAL: ", 0
str_pass dt "PASS: ", 0
str_fail dt " FAIL: ", 0
str_layout dt "LAYOUT:", 0
str_layout1 dt " TOP 1 ", 0
str_layout2 dt " 2 ", 0
str_layout3 dt " 3 ", 0
str_layout4 dt " BOT 4 ", 0
str_running dt "RUNNING", 0
str_dot dt ".", 0
str_insp_fin dt "INSPECTION FIN", 0
str_emerstop dt "EMERGENCY STOP", 0
str_null dt 0
; corresponds to the layout byte
char_layout dt "XFFPXFFP" ;"XF2P4567" ; "XFEPEEEE"
; corresponds to keypad
char_keynumber dt "123", 0, "456", 0, "789", 0, 0, "0", 0, 0
char_slash dt "/", 0
;????!!!!copy spaceX function

	code
#IFNDEF DEBUG
;*******************************************************************************
; "main": Main Function
; Func: Call initialization and then keep polling the keypad for
; input (or interrupt)
; Input: None
; Output: None
; Affect: *
;*******************************************************************************
main
	call init
keypoll
	btfsc KEYPAD_DA
	call keyresp
	call keypad_timeout
	goto keypoll
#ELSE
;*******************************************************************************
; "mac_test": Machenical System Test Function
; Func: Test the machenical system, each botton on keypad
; corresponds to a machine function (i.e. driver)
; Input: None
; Output: None
; Affect: *
;*******************************************************************************
mac_test
	call init_pic
	call reset_software
	;call reset_hardware
; PORT Reset/Initialization
; BANK0
	clrf PORTA ; RA4 (Reserved) output 0
	clrf PORTB ; RB0, 2, 3 (Reserved) output 0
	clrf PORTC ; VMOTOR disable, LED off
	clrf PORTD ; clear S0, S1 of SMOTOR
	clrf PORTE ; SMOTOR disable, clear S2, S3 of SMOTOR
	; LCD Reset/Initialization
	call LCD_init
	call display
mac_test_loop
	call analogtest2
	btfsc KEYPAD_DA
	call keyresp_ma
	movlw 0x64
	call delayX5msm
	goto mac_test_loop
keyresp_ma
	swapf PORTB, w
	andlw 0x0F
	TABLE
	;keyresp_switch_table
	goto kma0 ; keypressed = 0 "1" = SM forward
	goto kma1 ; keypressed = 1 "2" = SM backward
	goto kma2 ; keypressed = 2 "3" = SM step
	goto kma3 ; keypressed = 3 "A"
	goto kma4 ; keypressed = 4 "4" = DC up
	goto kma5 ; keypressed = 5 "5" = DC down
	goto kma6 ; keypressed = 6 "6" = DC stop
	goto kma7 ; keypressed = 7 "B"
	goto kma8 ; keypressed = 8 "7" = IRLED on
	goto kma9 ; keypressed = 9 "8" = IRLED off
	goto kmaA ; keypressed = A "9"
	goto kmaB ; keypressed = B "C"
	goto kmaC ; keypressed = C "*"
	goto kmaD ; keypressed = D "0"
	goto kmaE ; keypressed = E "#"
	goto kmaF ; keypressed = F "D"
kma_next
kma3
kma7
kmaA
kmaB
kmaC
kmaD
kmaE
kmaF
kma_release
	btfsc KEYPAD_DA ;Wait until key is released
	goto kma_release
	return
kma0
	movlw 0x00
	movwf smotor_dir
	call advancerow
	goto kma_next
kma1
	movlw 0x01
	movwf smotor_dir
	call advancerow
	goto kma_next
kma2
	bcf SMOTOR_EN
	goto kma_next
kma4
	call moveup
	goto kma_next
kma5
	call movedown
	goto kma_next
kma6
	bcf VMOTOR_C0
	bcf VMOTOR_C1
	goto kma_next
kma8
	IRLED_ON
	goto kma_next
kma9
	IRLED_OFF
	goto kma_next
;*******************************************************************************
; "analogtest2": Analog-to-Digital Test Function
; Func: Convert RA0 to digital and display its value every second
; Input:
; Output:
; Affect:
;*******************************************************************************
analogtest2
	STORE_LIGHT light_bg
	MOVLF temp5, COLS ; counter
	MOVLF temp2, LCDline ; LCDline addr
	MOVLF temp3, light_bg ; storage addr

	MOVFF FSR, temp3
	MOVFF temp4, INDF ; temp storage
	MOVFF FSR, temp2
	COPY_DEC3 temp4
	COPY_STRING str_dot
	COPY_STRING str_dot
	COPY_STRING str_dot
	MOVFF temp2, FSR
	incf temp3, f
	incf temp3, f
	MOVFF FSR, temp3
	MOVFF temp4, INDF ; temp storage
	MOVFF FSR, temp2
	COPY_DEC3 temp4
	COPY_STRING str_dot
	COPY_STRING str_dot
	COPY_STRING str_dot
	MOVFF temp2, FSR
	incf temp3, f
	incf temp3, f
	MOVFF FSR, temp3
	MOVFF temp4, INDF ; temp storage
	MOVFF FSR, temp2
	COPY_DEC3 temp4
	COPY_STRING str_dot
	COPY_STRING str_dot
	COPY_STRING str_dot
	MOVFF temp2, FSR
	call LCD_clear ; clear LCD display
	call writeline
	call LCD_line2
	MOVLF temp2, LCDline ; LCDline addr
	MOVLF temp3, light_bg ; storage addr
	incf temp3, f
	MOVFF FSR, temp3
	MOVFF temp4, INDF ; temp storage
	MOVFF FSR, temp2
	COPY_STRING str_dot
	COPY_STRING str_dot
	COPY_STRING str_dot
	COPY_DEC3 temp4
	COPY_STRING str_dot
	COPY_STRING str_dot
	COPY_STRING str_dot
	MOVFF temp2, FSR
	incf temp3, f
	incf temp3, f
	MOVFF FSR, temp3
	MOVFF temp4, INDF ; temp storage
	MOVFF FSR, temp2
	COPY_DEC3 temp4
	MOVFF temp2, FSR
	call writeline
	call LCD_out
;ADCtest2_loop2
; MOVFF FSR, temp3
; MOVFF temp4, INDF ; temp storage
; MOVFF FSR, temp2
; COPY_DEC3 temp4
;; COPY_STRING str_dot
; MOVFF temp2, FSR
; incf temp3, f
; decfsz temp5,f
; goto ADCtest2_loop2
;
; call LCD_clear ; clear LCD display
; call writeline
	return

;*******************************************************************************
; "analogtest": Analog-to-Digital Test Function
; Func: Convert RA0 to digital and display its value every second
; Input:
; Output:
; Affect:
;*******************************************************************************
analogtest
	ADCtest_loop
	call delay50us ; require 2Tosc + Tacq = 28us
	bsf ADCON0, GO
analog_poll ; about 40us
	btfsc ADCON0, GO
	goto analog_poll
	movf ADRESH, w
	MOVLF FSR, LCDline
	COPY_DEC1 ADRESH
	call LCD_clear ; clear LCD display
	call writeline
	; delay 0.5s
	movlw 0x64
	movwf temp
ADCtest_simpledelay
	call delay5ms
	decfsz temp, f
	goto ADCtest_simpledelay
	goto ADCtest_loop
#ENDIF

#IFNDEF DEBUG
;*******************************************************************************
; "interrupt": Interrupt Handle Function
; Func: Handle all interrupt that occurs in runtime
; Input: INTCON
; Output: INTCON, rt_*, newsec
; Affect: None (w_temp, status_temp)
;*******************************************************************************
interrupt
	movwf w_temp ; save W
	swapf STATUS, w ; save STATUS, note swapf will not affect STATUS
	BANK00
	movwf status_temp
	; movf PCLATH, w ; save page information
	; movwf pclath_temp
	; clrf PCLATH
	movf FSR, w ; save FSR
	movwf FSR_temp

	; Timer0 Interrupt Handle
	; T0IE always on, no test
	btfss INTCON, T0IF
	goto int_tmr0_skip
	incf rt_counter, f
	movf rt_counter, w ; test with 98h, correponds to 996,147.2us
	sublw 0x98
	btfss STATUS, Z
	goto int_tmr0_end ; rt_counter <> 98h
	clrf rt_counter ; rt_counter == 98h
	movlw rt_sec
	call addsec
	movlw rt_day
	btfsc STATUS, C
	call addday ; addday if carry from addsec
	MOVLF newsec, TRUE
int_tmr0_end
	bcf INTCON, T0IF
int_tmr0_skip
	; Keypad (PORTB) Change Interrupt
	btfss INTCON, RBIE ; interrept must be enabled first
	goto int_rb_skip
	btfss INTCON, RBIF
	goto int_rb_skip
	swapf PORTB, w ; test PORTB<7:4> against stop button
	andlw 0x0F
	sublw STOP_BUT
	btfss STATUS, Z
	goto int_rb_end
	; Emergency Stop!!!!
	bcf IRLED ; turn off IRLEDs
	bcf VMOTOR_C0 ; turn off v motor
	bcf VMOTOR_C1
	bcf SMOTOR_EN ; turn off s motor
	MOVLF FSR, LCDline ; display emergency stop
	COPY_STRING str_emerstop
	call LCD_clear ; clear LCD display
	call writeline
	call LCD_out
	stop goto stop ; hang the program
int_rb_end
	bcf INTCON, RBIF
int_rb_skip
	movf FSR_temp, w ; restore FSR
	movwf FSR
	; movf pclath_temp, w ; restore page information
	; movwf PCLATH
	swapf status_temp, w ; restore STATUS
	movwf STATUS
	swapf w_temp, f ; restore W, not affecting STATUS
	swapf w_temp, w
retfie

;*******************************************************************************
; "init": Initialization Function
; Func: Initialize chip settings, variables and reset hardware
; position
; Input: None
; Output: *
; Affect: W, STATUS, temp, delaytemp, delaycount, delaytemp2,
; delaycount2, delaytemp3, delaycount3
;*******************************************************************************
init
	call init_pic
	call reset_software
	;call reset_hardware
	call reset_realtime
	clrf TMR0 ; start timing
	bsf INTCON, T0IE
	bsf INTCON, GIE
	movlw PHASE_REALTIME
	movwf phase
	call display
	return
#ENDIF

;*******************************************************************************
; "init_pic": PIC Initialization Function
; Func: Initialize chip settings: Interrupt, TMR0, PORT, ADC
; Input: None
; Output: INTCON, TRISA, TRISB, TRISC, TRISD, TRISE, ADCCON0, ADCCON1
; Affect: W, STATUS
;*******************************************************************************
init_pic
; Interrupt Initialization
; Disable Global interrupt, diable peripheral interrupt, enable timer0 and
; PORTB interrupton change (keypad), diable RB0 interrupt
; #define INITVAL_INTCON B'00101000'
; movlw INITVAL_INTCON
clrf INTCON
;
;clrf SSPBUF
;BANK1
;clrf TXSTA
;clrf PIE1
;clrf PIE2
; Timer0 Initialization
	BANK0
	clrf TMR0
	clrf rt_counter
	BANK1
	movlw INITVAL_OPTREG
	movwf OPTION_REG
	; PORT Initialzation
	; BANK1
	movlw INITVAL_TRISA
	movwf TRISA
	movlw INITVAL_TRISB
	movwf TRISB
	movlw INITVAL_TRISC
	movwf TRISC
	movlw INITVAL_TRISD
	movwf TRISD
	movlw INITVAL_TRISE
	movwf TRISE

	; Analog to Digital Convertor Initialization
	; BANK1
	movlw INITVAL_ADCON1
	movwf ADCON1
	BANK0
	movlw INITVAL_ADCON0
	movwf ADCON0
	return

;*******************************************************************************
;"reset_software": Software Reset/Initialization Function
; Func: Reset all variables
; Input: None
; Output: phase, report_num, line_num, log_total, log_next, smotor_dir
; Affect: STATUS
;*******************************************************************************
reset_software
	movlw PHASE_HDINIT
	movwf phase
	clrf report_num
	clrf line_num
	clrf log_total
	clrf log_next
	MOVLF smotor_dir, 1
	return

;*******************************************************************************
;"reset_hardware": Hardware Reset/Initialization Function
; Func: Reset/Initialize hardwares to their default position:
; Pos Sensor Off, V DC Motor at top, S Motor at "Row 1",
; LCD, (RTC)
; Input: None
; Output: PORTA, PORTB, PORTC, PORTD, PORTE
; Affect: W, STATUS, temp, delaytemp, delaycount, delaytemp2,
; delaycount2, delaytemp3, delaycount3
;*******************************************************************************
reset_hardware
	; PORT Reset/Initialization
	; BANK0
	clrf PORTA ; RA4 (Reserved) output 0
	clrf PORTB ; RB0, 2, 3 (Reserved) output 0
	clrf PORTC ; VMOTOR disable, LED off
	clrf PORTD ; clear S0, S1 of SMOTOR
	clrf PORTE ; SMOTOR disable, clear S2, S3 of SMOTOR
	; LCD Reset/Initialization
	call LCD_init
	call display
	; Position Sensor(IRLED) Reset/Initialization: all off
	; Already done with PORT reset
	; Vertical DC Motor Reset/Initialization: move to top
	call moveup
	; Stepper Motor Reset/Initialization: move to "Row 4"
	clrf smotor_dir
	call advancerow ; 4 advance row to ensure to init pos
	call advancerow
	call advancerow
	call advancerow
	MOVLF smotor_dir, 1
	return

;*******************************************************************************
;"reset_realtime": Real Time Clock Reset/Initialization Function
; Func: Reset Real Time Clock
; Input: None (from Keypad)
; Output: rt_year, rt_month, rt_day, rt_hour, rt_min, rt_sec
; Affect:
;*******************************************************************************
	reset_realtime
	movlw PHASE_RTCINIT
	movwf phase
	clrf rt_year
	clrf rt_month
	clrf rt_day
	clrf rt_hour
	clrf rt_min
	clrf rt_sec
	; YYMMDD
	call LCD_clear ; clear LCD display
	MOVLF FSR, LCDline
	COPY_STRING str_enterymd
	call writeline
	call LCD_line2
	MOVLF FSR, LCDline
	COPY_STRING str_yearhead
	call writeline
	clrf temp3 ; number of valid numbers entered
reset_rt_ymd
	btfss KEYPAD_DA ; Wait until data is available from the keypad
	goto reset_rt_ymd
	swapf PORTB, W ; Read PortB<7:4> into W<3:0>
	andlw 0x0F
	addlw char_keynumber
	call literal ; Convert keypad value to LCD character (value is still held in W)
	addlw 0x00
	btfsc STATUS, Z ; test for valid input (number)
	goto reset_rt_ymdrl
	movwf temp2 ; hold the value
	call LCD_wt ; Write the value in W to LCD
	movlw 0x30
	subwf temp2, f ; convert ASCII to number
	movf temp3, w
	TABLE ; switch (temp)
	goto reset_rt_ymd0
	goto reset_rt_ymd1
	goto reset_rt_ymd2
	goto reset_rt_ymd3
	goto reset_rt_ymd4
	goto reset_rt_ymd5
reset_rt_ymd0
	movf temp2, w
	MULLW .10
	addwf rt_year, f
	incf temp3, f
	goto reset_rt_ymdrl
reset_rt_ymd1
	movf temp2, w
	addwf rt_year, f
	incf temp3, f
	goto reset_rt_ymdrl
reset_rt_ymd2
	movf temp2, w
	MULLW .10
	addwf rt_month, f
	incf temp3, f
	goto reset_rt_ymdrl
reset_rt_ymd3
	movf temp2, w
	addwf rt_month, f
	incf temp3, f
	goto reset_rt_ymdrl
reset_rt_ymd4
	movf temp2, w
	MULLW .10
	addwf rt_day, f
	incf temp3, f
	goto reset_rt_ymdrl
reset_rt_ymd5
	movf temp2, w
	addwf rt_day, f
	incf temp3, f
reset_rt_ymdrl
	btfsc KEYPAD_DA ; Wait until key is released
	goto reset_rt_ymdrl
	movlw 0x06 ; 6 chars entered
	subwf temp3, w
	btfss STATUS, C
	goto reset_rt_ymd
	; hhmmss
	call LCD_clear ; clear LCD display
	MOVLF FSR, LCDline
	COPY_STRING str_enterhms
	call writeline
	call LCD_line2
	clrf temp3 ; number of valid numbers entered
reset_rt_hms
	btfss KEYPAD_DA ; Wait until data is available from the keypad
	goto reset_rt_hms
	swapf PORTB, W ; Read PortB<7:4> into W<3:0>
	andlw 0x0F
	addlw char_keynumber
	call literal ; Convert keypad value to LCD character (value is still held in W)
	addlw 0x00
	btfsc STATUS, Z ; test for valid input (number)
	goto reset_rt_hmsrl
	movwf temp2 ; hold the value
	call LCD_wt ; Write the value in W to LCD
	movlw 0x30
	subwf temp2, f ; convert ASCII to number
	movf temp3, w
	TABLE ; switch (temp)
	goto reset_rt_hms0
	goto reset_rt_hms1
	goto reset_rt_hms2
	goto reset_rt_hms3
	goto reset_rt_hms4
	goto reset_rt_hms5
reset_rt_hms0
	movf temp2, w
	MULLW .10
	addwf rt_hour, f
	incf temp3, f
	goto reset_rt_hmsrl
reset_rt_hms1
	movf temp2, w
	addwf rt_hour, f
	incf temp3, f
	goto reset_rt_hmsrl
reset_rt_hms2
	movf temp2, w
	MULLW .10
	addwf rt_min, f
	incf temp3, f
	goto reset_rt_hmsrl
reset_rt_hms3
	movf temp2, w
	addwf rt_min, f
	incf temp3, f
	goto reset_rt_hmsrl
reset_rt_hms4
	movf temp2, w
	MULLW .10
	addwf rt_sec, f
	incf temp3, f
	goto reset_rt_hmsrl
	reset_rt_hms5
	movf temp2, w
	addwf rt_sec, f
	incf temp3, f
	reset_rt_hmsrl
	btfsc KEYPAD_DA ; Wait until key is released
	goto reset_rt_hmsrl
	movlw 0x06 ; 6 chars entered
	subwf temp3, w
	btfss STATUS, C
	goto reset_rt_hms
	return

;*******************************************************************************
; "keyresp": Key Response Function
; Func: Display information or run an inspection according to the
; pressed key
; Input: W: Index of the key that being pressed
; Output: All actions
; Affect:
;*******************************************************************************
keyresp
	swapf PORTB, w
	andlw 0x0F
	TABLE
;keyresp_switch_table
	goto realtime ; keypressed = 0 "1" = "real time"
	goto report ; keypressed = 1 "2" = "report"
	goto unused_key ; keypressed = 2 "3"
	goto unused_key ; keypressed = 3 "A"
	goto unused_key ; keypressed = 4 "4"
	goto unused_key ; keypressed = 5 "5"
	goto unused_key ; keypressed = 6 "6"
	goto unused_key ; keypressed = 7 "B"
	goto scroll_up ; keypressed = 8 "7" = "scroll up"
	goto report_last ; keypressed = 9 "8" = "report last"
	goto unused_key ; keypressed = A "9"
	goto stoprun ; keypressed = B "C" = "stop"
	goto scroll_down ; keypressed = C "*" = "scroll down"
	goto report_next ; keypressed = D "0" = "scroll up"
	goto unused_key ; keypressed = E "#"
	goto startrun ; keypressed = F "D" = "run"
unused_key
keyresp_next
wait_release
	btfsc KEYPAD_DA ; Wait until key is released????
	goto wait_release ; !!!!!!!!!!time
	call display
	; reset timeout!!!!!!!!!!
	return

realtime
	movlw PHASE_REALTIME
	movwf phase
	clrf line_num
	goto keyresp_next
report
	movlw PHASE_REPORT ; assuem log_total <> 0
	movf log_total, f
	btfsc STATUS, Z
	movlw PHASE_NOREPORT ; log_total == 0, no report
	movwf phase
	clrf line_num
	goto keyresp_next
report_last
; !!!! some ideas: must in REPORT phase; no change in line_num if at last report;
; do not go through report; if enter from other phase same fn to report;
; display report# and can go across upper/lower limit
	movf log_total, f
	btfsc STATUS, Z
	goto report ; log_total == 0, no report!!!!
	; lower bound = (log_next - log_total + MAXLOG) MOD MAXLOG
	movf log_total, w ; get lower bound
	subwf log_next, w
	addlw MAXLOG
	MODLW MAXLOG
	subwf report_num, w
	btfsc STATUS, Z
	goto report ; current report at lower bound!!!!"This is the last report"!!!!
	decf report_num, w ; get last report
	addlw MAXLOG ; make sure report_num between 0 and MAXLOG - 1
	MODLW MAXLOG
	movwf report_num
	call readlog
	goto report
report_next
	movf log_total, f
	btfsc STATUS, Z
	goto report ; log_total == 0, no report!!!!
	; upper bound = (log_next - 1 + MAXLOG) MOD MAXLOG
	decf log_next, w ; get upper bound
	addlw MAXLOG
	MODLW MAXLOG
	subwf report_num, w
	btfsc STATUS, Z
	goto report ; current report at upper bound!!!!
	incf report_num, w ; get next report
	MODLW MAXLOG ; make sure report_num between 0 and MAXLOG - 1
	movwf report_num
	call readlog
	goto report
scroll_up
	movlw PHASE_REPORT ; test phase == PHASE_REPORT
	subwf phase, w
	btfss STATUS, Z
	goto keyresp_next ; phase <> PHASE_REPORT, do nothing
	movf line_num, f ; phase == PHASE_REPORT, test line_num == 0
	btfss STATUS, Z
	decf line_num, f ; line_num <> 0, decrease line_num (scroll up)
	goto keyresp_next
scroll_down
	movlw PHASE_REPORT ; test phase == PHASE_REPORT
	subwf phase, w
	btfss STATUS, Z
	goto keyresp_next ; phase <> PHASE_REPORT, do nothing
	movlw MAXLINE ; phase == PHASE_REPORT, test line_num == MAXLINE????
	subwf line_num, w
	btfss STATUS, Z
	incf line_num, f ; line_num <> MAXLINE, increase line_num (scroll down)
	goto keyresp_next
startrun
	movlw PHASE_RUN
	movwf phase
	clrf line_num
	;!!!! call display
	call LCD_clear ; clear LCD display
	MOVLF FSR, LCDline
	COPY_STRING str_running
	call writeline
	call run
	MOVLF phase, PHASE_FINISH
	clrf line_num
	call display
	; call delay1sl
	MOVLF phase, PHASE_REPORT
	clrf line_num
	call display
	; assume run time is very long, key has been released
	return
stoprun
	goto keyresp_next

;*******************************************************************************
;"keypad_timeout":
; Func:
; Input:
; Output:
; Affect:
;*******************************************************************************
keypad_timeout
	movf newsec, f
	btfsc STATUS, Z
	goto kp_to_nonewsec ; newsec == 0(FALSE), skip
	call display ; newsec == TRUE, display the new sec
	clrf newsec
kp_to_nonewsec
; SLEEP test goes here!!!!
	return

;*******************************************************************************
; "display": Display Function (User Interface)
; Func: First make up the content to be displayed into LCDline
; according to phase and line_num, then print the string
; to the LCD
; Input: phase, line_num
; Output: None (to LCD)
; Affect: W, STATUS, FSR, temp2, table_temp, arg, arg2,
; delaytemp, delaycount, lcd_temp
;*******************************************************************************
display
; run phase does not use general display function
	movf phase, w
	sublw PHASE_RUN
	btfsc STATUS, Z
	return
	movf line_num, w ; current line#
	call makeline
	call LCD_clear ; clear LCD display
	call writeline
	incf line_num, w ; next line# in W, but not inc line#
	call makeline
	call LCD_line2
	call writeline
	call LCD_out ; move the cursor out of screen
	return
;*******************************************************************************
; "makeline": Displayable Line Make & Copy Function
; Func: Make lines to be displayed according to the phase and
; line number (W), copy it to the LCDline array
; Input: W = line # to be displayed, phase
; Output: FSR = point to the null termination of the line made &
; copied, (Copied line in LCDline)
; Affect: W, STATUS, temp2, temp3, table_temp, arg, arg2, literal_addr
;*******************************************************************************
makeline
	movwf temp2 ; line#
	MOVLF FSR, LCDline ; start from LCDline
	movf phase, w
	TABLE ; switch (phase)
	goto ML_hdinit ; phase == 0
	goto ML_rtcinit ; phase == 1
	goto ML_realtime ; phase == 2
	goto ML_noreport ; phase == 3
	goto ML_report ; phase == 4
	goto ML_run ; phase == 5
	goto ML_finish ; phase == 6
ML_hdinit
	movf temp2, w
	TABLE ; switch (temp2(line#))
	goto ML_hdinit_0 ; line# == 0
	goto ML_hdinit_1 ; line# == 1
ML_rtcinit ; display do not use this function
	COPY_STRING str_null ; null termination
	return
ML_realtime
	movf temp2, w
	TABLE ; switch (temp2(line#))
	goto ML_realtime_0 ; line# == 0
	goto ML_realtime_1 ; line# == 1
ML_noreport
	movf temp2, w
	TABLE ; switch (temp2(line#))
	goto ML_noreport_0 ; line# == 0
	goto ML_noreport_1 ; line# == 1
ML_report
	movf temp2, w
	TABLE ; switch (temp2(line#))
	goto ML_report_0 ; line# == 0
	goto ML_report_1 ; line# == 1
	goto ML_report_2 ; line# == 2
	goto ML_report_3 ; line# == 3
	goto ML_report_4 ; line# == 4
	goto ML_report_5 ; line# == 5
	goto ML_report_6 ; line# == 6
	goto ML_report_7 ; line# == 7
	goto ML_report_8 ; line# == 8
	goto ML_report_9 ; line# == 9
	goto ML_report_10 ; line# == 10
ML_run
	movf temp2, w
	TABLE ; switch (temp2(line#))
	goto ML_run_0 ; line# == 0
	goto ML_run_1 ; line# == 1
ML_finish
	movf temp2, w
	TABLE ; switch (temp2(line#))
	goto ML_finish_0 ; line# == 0
	goto ML_finish_1 ; line# == 1
ML_hdinit_0
	COPY_STRING str_init
	return
ML_hdinit_1
	COPY_STRING str_null
	return
ML_realtime_0
	COPY_STRING str_yearhead
	COPY_DEC2 rt_year
	COPY_STRING str_dash
	COPY_DEC2 rt_month
	COPY_STRING str_dash
	COPY_DEC2 rt_day
	return
ML_realtime_1
	COPY_DEC2 rt_hour
	COPY_STRING str_colon
	COPY_DEC2 rt_min
	COPY_STRING str_colon
	COPY_DEC2 rt_sec
	return
ML_noreport_0
	COPY_STRING str_noreport
	return
ML_noreport_1
	COPY_STRING str_null
	return
ML_report_0
	COPY_STRING str_entry
	; log# = (log_total - log_next + report_num + 1 + MAXLOG) MOD MAXLOG
	; also log# = MAXLOG if result == 0
	movf log_next, w
	subwf log_total, w
	addwf report_num, w
	addlw 0x01
	addlw MAXLOG
	MODLW MAXLOG
	btfsc STATUS, Z
	movlw MAXLOG ; result == 0, log# = MAXLOG
	movwf temp3
	COPY_DEC2 temp3
	COPY_STRING char_slash
	COPY_DEC2 log_total
	return
ML_report_1
	COPY_STRING str_start
	COPY_DEC2 st_hour
	COPY_STRING str_colon
	COPY_DEC2 st_min
	COPY_STRING str_colon
	COPY_DEC2 st_sec
	return
ML_report_2
	COPY_STRING str_finish
	COPY_DEC2 end_hour
	COPY_STRING str_colon
	COPY_DEC2 end_min
	COPY_STRING str_colon
	COPY_DEC2 end_sec
	return
ML_report_3
	COPY_STRING str_runtime
	COPY_DEC1 runtime
	COPY_STRING str_s
	return
ML_report_4
	COPY_STRING str_total
	COPY_DEC1 cl_total
	return
ML_report_5
	COPY_STRING str_pass
	COPY_DEC1 cl_pass
	COPY_STRING str_fail
	COPY_DEC1 cl_fail
	return
ML_report_6
	COPY_STRING str_layout
	return
ML_report_7
	COPY_STRING str_layout1
	COPY_LAYOUT 0
	return
ML_report_8
	COPY_STRING str_layout2
	COPY_LAYOUT 1
	return
ML_report_9
	COPY_STRING str_layout3
	COPY_LAYOUT 2
	return
ML_report_10
	COPY_STRING str_layout4
	COPY_LAYOUT 3
	return
ML_run_0
	COPY_STRING str_running
	return
ML_run_1
	COPY_STRING str_null
	return
ML_finish_0
	COPY_STRING str_insp_fin
	return
ML_finish_1 ; ALL PASS????!!!!
	COPY_STRING str_runtime
	COPY_DEC1 runtime
	COPY_STRING str_s
	return
;*******************************************************************************
; "copystring": String Copy Function
; Func: Copy the string literal (null terminated) pointed by W
; to position pointed by FSR (indirect pointer)
; Input: W = address of the string literal wanted,
; FSR = adress of destination
; Output: FSR = adress of the null terminator of the copyed string
; Affect: W, STATUS, literal_addr
;*******************************************************************************
copystring
	movwf literal_addr
copystring_loop
	movf literal_addr, w
	call literal
	movwf INDF
	movf INDF, f ; test INDF(last char) == 0(NULL)
	btfsc STATUS, Z
	return ; if end of string is reached (NULL)
	incf FSR, f
	incf literal_addr, f
	goto copystring_loop
;*******************************************************************************
; "copylayout": Layout Row Translate & Copy Function
; Func: Translate a row in layout array into printable format,
; copy it to position pointed by FSR,
; and add a null termination after the copied charactor
; Input: W = raw number, FSR = adress of destination
; Output: FSR = adress of the null terminator after copied layout
; Affect:
;*******************************************************************************
copylayout
	movwf temp ; raw number, later hold translated layout byte
	movlw layout
	movf temp, f ; test if temp == 0
	btfsc STATUS, Z
	goto copylayout_next ; temp == 0, starting position = layout
copylayout_startloop
	addlw COLS
	decfsz temp, f
	goto copylayout_startloop
copylayout_next
	movwf temp2 ; address of layout byte
	movf FSR, w
	movwf temp3 ; address of destination
	movlw COLS
	movwf temp4 ; colume counter
copylayout_charloop
	movf temp2, w ; get layout byte
	movwf FSR
	movlw char_layout ; get translated layout byte address
	addwf INDF, w
	call literal ; translate char
	movwf temp ; save the translated layout byte into temp
	movf temp3, w ; get destination
	movwf FSR
	movf temp, w ; copy translated byte to destination
movwf INDF
	incf temp2, f
	incf temp3, f
	decfsz temp4, f
	goto copylayout_charloop
	movf temp3, w
	movwf FSR ; FSR will now have the address after last byte
	movlw NULL ; add null terminator
	movwf INDF
	return
;*******************************************************************************
; "copydec": Byte Display Conversion & Copy Function
; Func: Convert a number store in a byte to a printable decimal
; ASCII string with null termination and copy it to a position
; pointed by FSR
; Input: arg = number to be converted,
; arg2 = minimum number of digits displayed
; FSR = adress of destination
; Output: FSR = adress of the null terminator of the decimal display
; Affect: W, STATUS, arith_temp, arith_temp2
;*******************************************************************************
copydec
	movf arg, w
	DIVLW 0x64 ; 100
	btfss STATUS, Z ; test if quotient is 0
	goto copydec_copyhundreds ; quotient <> 0, normal display
	movlw 0x03 ; quotient == 0, depends on arg2
	subwf arg2, w
	btfss STATUS, C ; test if arg2 < 3
	goto copydec_tens ; arg2 < 3, skip 0 hundred
	movlw 0x00 ; arg2 >= 3, display 0
copydec_copyhundreds
	addlw 0x30 ; num+0x30 = its ASCII
	movwf INDF
	incf FSR, f
	movlw 0x03 ; hundreds already displayed, set arg2 to 3
	movwf arg2 ; because all following digit shall be seen
copydec_tens
	movf arg, w
	MODLW 0x64 ; 100
	DIVLW 0x0A ; 10
	btfss STATUS, Z ; test if quotient is 0
	goto copydec_copytens ; quotient <> 0, normal display
	movlw 0x02 ; quotient == 0, depends on arg2
	subwf arg2, w
	btfss STATUS, C ; test if arg2 < 2
	goto copydec_ones ; arg2 < 2, skip 0 tens
	movlw 0x00 ; arg2 >= 2, display 0
copydec_copytens
	addlw 0x30 ; num+0x30 = its ASCII
	movwf INDF
	incf FSR, f
	; movlw 0x02 ; tens already displayed, set arg2 to 2
	; movwf arg2 ; because all following digit shall be seen
copydec_ones
	movf arg, w
	MODLW 0x0A ; 10
	; ones shall be displayed anyways
	addlw 0x30 ; num+0x30 = its ASCII
	movwf INDF
	incf FSR, f
copydec_ending ; write a null ending
	movlw NULL
	movwf INDF
	return
;*******************************************************************************
; "writeline": Write Displayable Line to LCD Function
; Func: Send LCDline string to LCD charactor by charactor
; Input: None (string prepared in LCDline)
; Output: None (to LCD)
; Affect: W, STATUS, FSR, delaytemp, delaycount
; Runtime: (3.2 + 216.0 * N) us, N = # of char, not including NULL
;*******************************************************************************
writeline
	MOVLF FSR, LCDline
writeline_loop
	movf INDF, w ; test INDF(char pointer to the string)==0(NULL)
	btfsc STATUS, Z
	return ; if end of string is reached (NULL)
	call LCD_wt
	incf FSR, f
	goto writeline_loop
;*******************************************************************************
; "Run": Run Inspection Function
; Func: Control the entire process of inspection
; Input: None
; Output: st_year, st_month, st_day, st_hour, st_min, st_sec,
; end_hour, end_min, end_sec, runtime, cl_total, cl_pass,
; cl_fail, layout, smotor_dir, log!!!!
; Affect:
;*******************************************************************************
run
	; store sarting time
	MOVFF st_year, rt_year
	MOVFF st_month, rt_month
	MOVFF st_day, rt_day
	MOVFF st_hour, rt_hour
	MOVFF st_min, rt_min
	MOVFF st_sec, rt_sec
	; reset all layouts
	MOVLF FSR, layout
	MOVLF temp, MAXPOS
run_clearlayoutloop
	clrf INDF
	incf FSR, f
	decfsz temp, f
	goto run_clearlayoutloop
	; initialize variables
	movlw layout
	movf smotor_dir, f
	btfsc STATUS, Z
	goto run_init_smotornext; smotor_dir == 0, "row1" to "row4"
	addlw MAXPOS ; smotor_dir <> 0, "row4" to "row1"
	movwf temp ; temperary storage
	movlw COLS
	subwf temp, w ; layout + MAXPOS - COLS, at last row
run_init_smotornext
	movwf result_addr
	MOVLF rowleft, ROWS
	clrf cl_total
	clrf cl_pass
	clrf cl_fail
	bcf INTCON, RBIF
	bsf INTCON, RBIE ; enable keypad interrept
	STORE_LIGHT light_bg
	PRINT_DOT ; !!!!
run_loop
	IRLED_ON
	STORE_LIGHT light_pos
	IRLED_OFF
	movf result_addr, w
	CALC_POS THD_IRLED
	btfsc STATUS, Z
	goto run_noextrarow ; return value == 0, no lights in this row
	;PRESS_CL
	call movedown
	STORE_LIGHT light_pos
	CALC_POS THD_CL3LED
	call moveup
	STORE_LIGHT light_cl
	PRINT_DOT ; !!!!
	;PRESS_CL
	call movedown
	call moveup
	STORE_LIGHT light_off
	PRINT_DOT ; !!!!
	movf result_addr, w
	call calcfunc
	addlw 0x00
	btfsc STATUS, Z
	goto run_noextrarow ; return value == 0, no extra row
	; return value <> 0, advance extra row
	; advance to next RAM location
	movlw COLS
	movf smotor_dir, f
	btfss STATUS, Z
	goto run_nextRAM_reverse; smotor_dir<>0, "row4" to "row1", sub COLS
	addwf result_addr, f ; smotor_dir == 0, "row1" to "row4", add COLS
	goto run_nextRAM_next
run_nextRAM_reverse
	subwf result_addr, f
run_nextRAM_next
	decf rowleft, f
	btfsc STATUS, Z
	goto run_end ; no row left, end run
	call advancerow ; advance to next machine location
	PRINT_DOT ; !!!!
run_noextrarow
	; advance to next RAM location
	movlw COLS
	movf smotor_dir, f
	btfss STATUS, Z
	goto run_nextRAM_reverse2 ; smotor_dir <> 0, "row4" to "row1"
	addwf result_addr, f ; smotor_dir == 0, "row1" to "row4", add COLS
	goto run_nextRAM_next2
run_nextRAM_reverse2
	subwf result_addr, f
run_nextRAM_next2
	decf rowleft, f
	btfsc STATUS, Z
	goto run_end ; no row left, end run
	call advancerow ; advance to next machine location
	PRINT_DOT ; !!!!
	goto run_loop
run_end
	bcf INTCON, RBIE ; disable keypad interrept
	movlw 0x01 ; mask last bit
	xorwf smotor_dir, f ; logic NOT last digit, reverse direction
	; store end time
	MOVFF end_hour, rt_hour
	MOVFF end_min, rt_min
	MOVFF end_sec, rt_sec
	call calcruntime
	call writelog
	movwf report_num
	return
;*******************************************************************************
; "calcpos": Row Position Calculation Function
; Func: Determine the existance of closet light at any positions in
; current row: result CL_POS_BIT = (light_pos >= THD_IRLED)
; Input: W = the starting address where the result will be stored,
; temp = address of the result, temp4 = threshold, light_pos[]
; Output: W = number of lights in current row, result bytes,
; STATUS is set according to W
; Affect: FSR, temp, temp2, temp3, temp4
;*******************************************************************************
calcpos
	; movwf temp ; address of the result
	clrf temp2 ; colume number
	clrf temp3 ; number of CLs in current row
calcpos_loop
	MOVFF FSR, temp
	movlw light_pos
	addwf temp2, w
	movwf FSR ; get current light_pos
	movf temp4, w
	subwf INDF, w ; light_pos - threshold
	btfss STATUS, C
	goto calcpos_next ; light_pos < threshold, no light
	MOVFF FSR, temp ; light_pos >= threshold, has light
	bsf INDF, CL_POS_BIT ; set pos bit
	incf temp3, f
calcpos_next
	incf temp, f
	incf temp2, f
	movlw COLS
	subwf temp2, w ; temp2(col#) - COLS(max col#)
	btfss STATUS, C
	goto calcpos_loop ; temp2(col#) < COLS(max col#)
	movf temp3, w
	return
;*******************************************************************************
; "calcfunc": Row Functionality Calculation Function
; Func: Determine the functionality of closet light at ANY positions
; (not only those maked pos) of current row, also determine
; whether next row can physically have any CL
; Input: W = the starting address where the result will be stored,
; light_bg[], light_cl[], light_off[], result bytes
; Output: W = whether the machine need to advance one more row
; (0 = advance one row; 1 = advance two rows),
; cl_total, cl_pass, cl_fail, layout[]
; Affect: STATUS, FSR, temp, temp2, temp3, temp4, temp5, temp6, temp7
;*******************************************************************************
calcfunc
movwf temp ; address of the result
clrf temp2 ; colume number
clrf temp3 ; C0 = light_pos >= THD_IRLED
clrf temp4 ; C1 = light_cl >= THD_CL3LED
clrf temp5 ; C2 = light_off >= (lihgt_bg + THD_BG)
clrf temp6 ; number of CLs in current row
clrf temp7 ; temperaty storage
calcfunc_loop
; get C0 = CL_POS_BIT from calcpos
MOVFF FSR, temp
movlw FALSE
btfsc INDF, CL_POS_BIT
movlw TRUE ; CL_POS_BIT set, C0 = true
movwf temp3
; get C1 = light_cl >= THD_CL3LED
movlw light_cl
addwf temp2, w
movwf FSR ; get current light_cl
movlw THD_CL3LED
subwf INDF, w ; light_cl - THD_CL3LED
btfss STATUS, C
goto calcfunc_C1false ; light_pos < THD_IRLED, C1 = false
movlw TRUE ; light_pos >= THD_IRLED, C1 = ture
goto calcfunc_C1next
calcfunc_C1false
movlw FALSE
calcfunc_C1next
movwf temp4
; get C2 = light_off >= (lihgt_bg + THD_BG)
movlw light_bg
addwf temp2, w
movwf FSR ; get current light_bg
movlw THD_BG
addwf INDF, w ; lihgt_bg + THD_BG
movwf temp7 ; temperally save
movlw light_off
addwf temp2, w
movwf FSR ; get current light_off
movf temp7, w ; put (lihgt_bg + THD_BG) back
subwf INDF, w ; light_off - (lihgt_bg + THD_BG)
btfss STATUS, C
goto calcfunc_C2false ; light_off < (lihgt_bg - THD_BG), C2 = false
movlw TRUE ; light_off >= (lihgt_bg - THD_BG), C2 = true
goto calcfunc_C2next
calcfunc_C2false
movlw FALSE
calcfunc_C2next
movwf temp5
; determine the functionality of CL:
MOVFF FSR, temp
clrf INDF ; reset layout byte
; CL_POS_BIT = C0 IOR C1 IOR C2
movf temp3, w ; W = C0
iorwf temp4, w ; W = C0 IOR C1
iorwf temp5, w ; W = C0 IOR C1 IOR C2
btfsc STATUS, Z
goto calcfunc_POSfalse ; W == 0, false
bsf INDF, CL_POS_BIT ; W <> 0, true
incf cl_total, f
incf temp6, f
calcfunc_POSfalse
; CL_FN_BIT = (C1 AND (NOT C2)) IOR (C0 AND (NOT C1) AND C2)
movf temp5, w ; W = C2
xorlw 0xFF ; W = NOT C2
andwf temp4, w ; W = C1 AND (NOT C2)
 movwf temp7 ; temperally save
movf temp4, w ; W = C1
xorlw 0xFF ; W = NOT C1
andwf temp3, w ; W = C0 AND (NOT C1)
andwf temp5, w ; W = C0 AND (NOT C1) AND C2
iorwf temp7, w ; W = (C1 AND(NOT C2))IOR(C0 AND(NOT C1)AND C2)
btfsc STATUS, Z
goto calcfunc_FNfalse ; W == 0, false
bsf INDF, CL_FN_BIT ; W <> 0, true
incf cl_pass, f
calcfunc_FNfalse
; CL_ERR_BIT = (C1 AND (NOT C0)) IOR (C2 AND (NOT C1))
movf temp4, w ; W = C1
xorlw 0xFF ; W = NOT C1
andwf temp5, w ; W = C2 AND (NOT C1)
movwf temp7 ; temperally save
movf temp3, w ; W = C0
xorlw 0xFF ; W = NOT C0
andwf temp4, w ; W = C1 AND (NOT C0)
iorwf temp7, w ; W = (C1 AND (NOT C0)) IOR (C2 AND (NOT C1))
btfss STATUS, Z
bsf INDF, CL_ERR_BIT ; W <> 0, true
incf temp, f
incf temp2, f
movlw COLS
subwf temp2, w ; temp2(col#) - COLS(max col#)
btfss STATUS, C
goto calcfunc_loop ; temp2(col#) < COLS(max col#)
; cl_fail = cl_total - cl_pass
movf cl_pass, w
subwf cl_total, w ; cl_total - cl_pass
movwf cl_fail
; advance two rows if "CLs in this row" >= MAXCLINROW
movlw MAXCLINROW
subwf temp6, w ; "CLs in this row" - MAXCLINROW
btfss STATUS, C
retlw 0x00 ; "CLs in this row" < MAXCLINROW
retlw 0x01 ; "CLs in this row" >= MAXCLINROW
;*******************************************************************************
; "calcruntime": Runtime Calculation Function
; Func: Calculate the running time of the run = endtime - starttime
; Input: st_min, st_sec, end_min, end_sec
; Output: runtime
; Affect: W, STATUS, temp
;*******************************************************************************
calcruntime
    movf st_min, w ; temp = end_min - st_min
    subwf end_min, w
    btfsc STATUS, C
    goto calcruntime_next1
    addlw .60 ; borrow occur, +60min
calcruntime_next1
    movwf temp
    movf st_sec, w ; W = end_sec - st_sec
    subwf end_sec, w
    btfsc STATUS, C
    goto calcruntime_next2
    addlw .60 ; borrow occur, +60sec
    decf temp, f ; -1min
calcruntime_next2
    movf temp, f
    btfsc STATUS, Z
    goto calcruntime_next3 ; temp == 0, runtime = W
calcruntime_loop ; runtime = W + .60*temp
    addlw .60
    btfsc STATUS, C
    goto calcruntime_overflow ; W>255 overflow
    decfsz temp, f
    goto calcruntime_loop
calcruntime_next3
    movwf runtime
    return
calcruntime_overflow
    movlw 0xFF ; !!!!
    movwf runtime
return
;*******************************************************************************
; "lightsensor": Light Sensor Read, A/D Convert, and Store Function
; Func: Read in analog signal from light sensor, convert it to
; digital, and store the most significant 8-bit result to
; designated address, convert voltage reading to intensity,
; take average of LIGHTAVGX readings,
; repeat COLS times for a row
; Input: W = the staring address where the readings will be stored
; Output: readings store into designated bytes
; Affect: W, STATUS, FSR, ADCON0, ADRESH, ADRESL, temp, temp2, temp3
; delaytemp, delaycount, arith_temp, arith_temp2
;*******************************************************************************
lightsensor
    movwf FSR
    clrf temp ; CHS (Channel Select) bits
    MOVLF temp2, COLS ; number of colume left
lightsensor_loop_col
    movlw B'11000111' ; mask CHS bits
    andwf ADCON0, f ; clear CHS bits
    movf temp, w
    iorwf ADCON0, f ; set CHS bits
    ; avergae = (X1/n) + (X2/n) + ... + (Xn/n)
    MOVLF temp3, LIGHTAVGX ; count of sample light sensor reading
    clrf INDF
lightsensor_loop_avg
    call delay50us ; require 2Tosc + Tacq = 28us
    bsf ADCON0, GO
lightsensor_poll ; about 40us
    btfsc ADCON0, GO
    goto lightsensor_poll
    movf ADRESH, w ; the most significant 8-bit result
    xorlw 0xFF ; invert result, since 5V = 0 intensity!!!!
    DIVLW LIGHTAVGX
    addwf INDF, f
    decfsz temp3, f
    goto lightsensor_loop_avg
    movlw B'00001000'
    addwf temp, f ; advance CHS
    incf FSR, f
    decfsz temp2, f
    goto lightsensor_loop_col
return

;*******************************************************************************
; "ledcontrol": IR LEDs Control Function
; Func: Turn on or off the infrared LEDs according to W
; Input: W = turn on or off the LED (0=off or else=on)
; Output: None
; Affect: STATUS
; Runtime: 3.2 us
;*******************************************************************************
ledcontrol
    bcf IRLED
    addlw 0x00
    btfss STATUS, Z
    bsf IRLED ; if w <> 0, set IRLED
return
;*******************************************************************************
; "movedown": Arm Move Down Control Function
; Func: Order the test arm to move down to the Closet Lights
; Input: None
; Output: None
; Affect: VMOTOR_C0, VMOTOR_C1
; Runtime: ???? us
;*******************************************************************************
movedown
    bsf SMOTOR_EN ; power s_motor to hold position
    bcf VMOTOR_C1 ; to be safe
    bsf VMOTOR_C0
    ;movedown_poll
    ; btfsc FB_BOT
    ; goto movedown_poll
    movlw DCDOWNDELAY
    call delayX100msm
    bcf VMOTOR_C0
    bcf SMOTOR_EN
return
;*******************************************************************************
; "moveup": Arm Move Up Control Function
; Func: Order the test arm to move up to its default position
; Input: None
; Output: None
; Affect: VMOTOR_C0, VMOTOR_C1
; Runtime: ???? us
;*******************************************************************************
moveup
    bsf SMOTOR_EN ; power s_motor to hold position
    bcf VMOTOR_C0 ; to be safe
    bsf VMOTOR_C1
    moveup_poll
    btfsc FB_TOP
    goto moveup_poll
    bcf VMOTOR_C1
    bcf SMOTOR_EN
return
;*******************************************************************************
; "advancerow": Arm Advance-to-Next-Row Control Function
; Func: Order the test arm to the next(determined by smotor_dir) row
; Input: smotor_dir = direction of stpper motor
; (0 = "Row 1" to "Row 4"; 1 = "Row 4" to "Row 1")
; Output: None
; Affect: W, STATUS, temp, SMOTOR_EN, SMOTOR_S0, SMOTOR_S1, SMOTOR_S2,
; SMOTOR_S3, delaytemp, delaycount, delaytemp2, delaycount2,
; delaytemp3, delaycount3
;*******************************************************************************
advancerow
    bcf SMOTOR_S1 ; state init
    bsf SMOTOR_S3
    bsf SMOTOR_EN ; start motor
    movlw SMOTOR_STEPS
    movwf temp
    movlw SMOTOR_SPD_F ; note: w must keep its value until very end
    movf smotor_dir, f
    btfss STATUS, Z
    goto advancerow_backwardloop
    advancerow_forwardloop ; smotor_dir == 0, "Row 1" to "Row 4"
    bcf SMOTOR_S0
    bsf SMOTOR_S2
    btfss FB_ROW4
    goto advancerow_end
    call delayX5msm
    bcf SMOTOR_S3
    bsf SMOTOR_S1
    btfss FB_ROW4
    goto advancerow_end
    call delayX5msm
    bcf SMOTOR_S2
    bsf SMOTOR_S0
    btfss FB_ROW4
    goto advancerow_end
    call delayX5msm
    bcf SMOTOR_S1
    bsf SMOTOR_S3
    btfss FB_ROW4
    goto advancerow_end
    call delayX5msm
    decfsz temp, f
    goto advancerow_forwardloop
    goto advancerow_end
    advancerow_backwardloop ; smotor_dir <> 0, "Row 4" to "Row 1"
    bcf SMOTOR_S3
    bsf SMOTOR_S1
    call delayX5msm
    bcf SMOTOR_S0
    bsf SMOTOR_S2
    call delayX5msm
    bcf SMOTOR_S1
    bsf SMOTOR_S3
    call delayX5msm
    bcf SMOTOR_S2
    bsf SMOTOR_S0
    call delayX5msm
    decfsz temp, f
    goto advancerow_backwardloop
    advancerow_end
    bcf SMOTOR_EN
return
;*******************************************************************************
; "writelog": Log Write Function
; Func: Write the result of current run to log
; Input: st_year, st_month, st_day, st_hour, st_min, st_sec,
; runtime, layout[], log_total, log_next
; Output: W = current log index, log_total, log_next, Log Entry
; Affect: STATUS, FSR, temp, temp2, temp3, temp4,
; arith_temp, arith_temp2
;*******************************************************************************
writelog
	; starting address (indirect) offset = (log_next / MAXLOGBANK) * 0x80 + 0x10
	movf log_next, w
	DIVLW MAXLOGBANK
	MULLW 0x80
	addlw 0x10
	movwf temp ; save in temp
	; starting address (indirect) = (log_next MOD MAXLOGBANK)*LOGLENGTH + offset
	movf log_next, w
	MODLW MAXLOGBANK ; W = log_next mod MAXLOGBANK
	MULLW LOGLENGTH
	addwf temp, w
	; store easy-access variables
	bsf STATUS, IRP ; BANK2&3 indirect access
	movwf FSR ; log addr + 0
	MOVFF INDF, runtime
	incf FSR, f ; log addr + 1
	swapf st_year, w
	addwf st_month, w
	movwf INDF
	incf FSR, f ; log addr + 2
	MOVFF INDF, st_day
	incf FSR, f ; log addr + 3
	MOVFF INDF, st_hour
	incf FSR, f ; log addr + 4
	MOVFF INDF, st_min
	incf FSR, f ; log addr + 5
	MOVFF INDF, st_sec
	incf FSR, f ; log addr + 6
	; store layout
	MOVFF temp, FSR ; the address of log entry (start at + 6)
	MOVLF temp2, layout ; address of layout bytes
	MOVLF temp3, MAXPOS ; position counter
writelog_layoutloop ; copy layout bytes in pairs
	; write upper ribble
	MOVFF FSR, temp2 ; get first layout byte
	bcf STATUS, IRP ; BANK0&1 indirect access
	swapf INDF, w
	movwf temp4 ; temp4 hold the swaped layout byte temperally
	MOVFF FSR, temp ; log entry
	bsf STATUS, IRP ; BANK2&3 indirect access
	MOVFF INDF, temp4
	incf temp2, f
	decf temp3, f
	btfsc STATUS, Z
	goto writelog_layoutnext
	; write lower ribble
	MOVFF FSR, temp2 ; get second layout byte
	bcf STATUS, IRP ; BANK0&1 indirect access
	MOVFF temp4, INDF ; temp4 hold the layout byte temperally
	MOVFF FSR, temp ; log entry
	bsf STATUS, IRP ; BANK2&3 indirect access
	movf temp4, w
	addwf INDF, f
	incf temp2, f
	incf temp, f
	decfsz temp3, f
	goto writelog_layoutloop
writelog_layoutnext
	; calculate new log_next = (log_next + 1) MOD MAXLOG
	MOVFF temp, log_next ; save current log index in temp
	incf log_next, f
	movlw MAXLOG ; test if max log reached
	subwf log_next, w ; log_next + 1 - MAXLOG
	btfss STATUS, C
	addlw MAXLOG ; log_next + 1 < MAXLOG, add MAXLOG back
	movwf log_next ; log_next = (log_next + 1) MOD MAXLOG
	; calculate new log_total
	movlw MAXLOG
	subwf log_total, w ; log_total - MAXLOG
	btfss STATUS, C
	incf log_total, f ; log_total < MAXLOG, increase total number
	movf temp, w ; resume current log entry index
	bcf STATUS, IRP ; back to BANK0&1 indirect access
	return
;*******************************************************************************
; "readlog": Log Read Function
; Func: Read the log of specified run
; Input: W = index of wanted report
; Output: st_year, st_month, st_day, st_hour, st_min, st_sec,
; end_hour, end_min, end_sec, runtime, cl_total, cl_pass,
; cl_fail, layout[]
; Affect: W, STATUS, FSR, temp, temp2, temp3, temp4,
; arith_temp, arith_temp2
;*******************************************************************************
readlog
	movwf temp2 ; save the index in temp2
	clrf cl_total
	clrf cl_pass
	; starting address (indirect) offset = (index / MAXLOGBANK) * 0x80 + 0x10
	DIVLW MAXLOGBANK
	MULLW 0x80
	addlw 0x10
	movwf temp ; save in temp
	; starting address (indirect) = (index MOD MAXLOGBANK)*LOGLENGTH + offset
	movf temp2, w ; resume index
	MODLW MAXLOGBANK ; W = index mod MAXLOGBANK
	MULLW LOGLENGTH
	addwf temp, w
	; read easy-access variables
	bsf STATUS, IRP ; BANK2&3 indirect access
	movwf FSR ; log addr + 0
	MOVFF runtime, INDF
	incf FSR, f ; log addr + 1
	swapf INDF, w ; swap upper 4 bits and lower 4 bits
	andlw 0x0F ; mask the lower 4 bits only
	movwf st_year
	movf INDF, w
	andlw 0x0F ; mask the lower 4 bits only
	movwf st_month
	incf FSR, f ; log addr + 2
	MOVFF st_day, INDF
	incf FSR, f ; log addr + 3
	MOVFF st_hour, INDF
	incf FSR, f ; log addr + 4
	MOVFF st_min, INDF
	incf FSR, f ; log addr + 5
	MOVFF st_sec, INDF
	incf FSR, f ; log addr + 6
	 ; read layout[], cl_total and cl_pass
	MOVFF temp, FSR ; the address of log entry (start at + 6)
	MOVLF temp2, layout ; address of layout bytes
	MOVLF temp3, MAXPOS ; position counter
readlog_layoutloop ; read layout bytes in pairs
	; read upper ribble
	MOVFF FSR, temp ; log entry
	bsf STATUS, IRP ; BANK2&3 indirect access
	swapf INDF, w
	andlw 0x0F ; mask the lower 4 bits only (not 3 bits!!!!)
	movwf temp4 ; temp4 hold the swaped layout byte temperally
	MOVFF FSR, temp2 ; get first layout byte
	bcf STATUS, IRP ; BANK0&1 indirect access
	MOVFF INDF, temp4
	btfsc INDF, CL_POS_BIT
	incf cl_total, f
	btfsc INDF, CL_FN_BIT
	incf cl_pass, f
	incf temp2, f
	decf temp3, f
	btfsc STATUS, Z
	goto readlog_layoutnext
	; read lower ribble
	MOVFF FSR, temp ; log entry
	bsf STATUS, IRP ; BANK2&3 indirect access
	movf INDF, w
	andlw 0x0F ; mask the lower 4 bits only (not 3 bits!!!!)
	movwf temp4 ; temp4 hold the layout byte temperally
	MOVFF FSR, temp2 ; get second layout byte
	bcf STATUS, IRP ; BANK0&1 indirect access
	MOVFF INDF, temp4
	btfsc INDF, CL_POS_BIT
	incf cl_total, f
	btfsc INDF, CL_FN_BIT
	incf cl_pass, f
	incf temp2, f
	incf temp, f
	decfsz temp3, f
	goto readlog_layoutloop
readlog_layoutnext
	; calculate end time
	MOVFF end_hour, st_hour
	MOVFF end_min, st_min
	MOVFF end_sec, st_sec
	movf runtime, w
	DIVLW .60
	addwf end_min, f ; end_min = st_min + runtime / .60
	movf runtime, w
	MODLW .60
	addwf end_sec, f ; end_sec = st_sec + runtime MOD .60
	movlw .60 ; test if 60s
	subwf end_sec, w ; w = end_sec - 60
	btfss STATUS, C
	goto readlog_endsec_next; end_sec < 60, end_sec OK
	movlw .60 ; end_sec >= 60, +1min, -60s
	subwf end_sec, f
	incf end_min, f
readlog_endsec_next
	movlw .60 ; test if 60min
	subwf end_min, w
	btfss STATUS, C
	goto readlog_next ; end_min < 60, end_min OK, end_hour should OK
	movlw .60 ; end_min >= 60, +1h, -60min
	subwf end_min, f
	incf end_hour, f
	movlw .24 ; test if 24h
	subwf end_hour, w
	btfss STATUS, C
	goto readlog_next
	movlw .24 ; >24h, -24h
	subwf end_hour, f
readlog_next
	; cl_fail = cl_total - cl_pass
	movf cl_pass, w
	subwf cl_total, w
	movwf cl_fail
	bcf STATUS, IRP ; back to BANK0&1 indirect access
	return
;*******************************************************************************
; "addsec": Add One Second Function
; Func: Add one second to the second byte of a timer,!!!!!!!!!!!!!!
; increase minute and hour bytes if necessary,
; carry out if day increment occur
; Input: W = Address of the second byte, min byte and hour byte
; should be at address W-1 and W-2, respectively
; Output: set STATUS C for day carry out
; Affect: W, FSR
; Runtime: 3.6us/6.4us/9.2us/10.0us
;*******************************************************************************
addsec
	movwf FSR
	incf INDF, f ; +1sec
	movlw .60
	subwf INDF, w ; W = INDF - 60, test if 60s
	btfss STATUS, C
	return ; INDF < 60, C==0, function done
	clrf INDF ; >=60s, clear sec
	decf FSR, f ; now FSR has address of min byte
	incf INDF, f ; +1min
	movlw .60
	subwf INDF, w ; W = INDF - 60, test if 60min
	btfss STATUS, C
	return ; INDF < 60, C==0, function done
	clrf INDF ; >=60min, clear min
	decf FSR, f ; now FSR has address of hour byte
	incf INDF, f ; +1hour
	movlw .24
	subwf INDF, w ; W = INDF - 24, test if 24hour
	btfss STATUS, C
	return ; INDF < 24, C==0, function done
	clrf INDF ; >=24h, clear hour
	return ; C has been set
;*******************************************************************************
; "addday": Add One Day Function
; Func: Add one day to the day byte of a timer,
; increase month and year bytes if necessary, !!!!unfinish
; Input: W = Address of the day byte, month byte and year byte
; should be at address W-1 and W-2, respectively
; Output: None
; Affect: W, STATUS, FSR
; Runtime: 3.6us/6.4us/8.0us
;*******************************************************************************
addday
	movwf FSR
	incf INDF, f ; +1day
	movlw .31 ; assume 1 month always= 30 days !!!!
	subwf INDF, w ; W = INDF - 31, test if over 30days
	btfss STATUS, C
	return ; INDF < 31, C==0, function done
	clrf INDF ; >=31s, clear day
	incf INDF ; day default at 1
	decf FSR, f ; now FSR has address of month byte
	incf INDF, f ; +1month
	movlw .13
	subwf INDF, w ; W = INDF - 13, test if over 12month
	btfss STATUS, C
	return ; INDF < 13, C==0, function done
	clrf INDF ; >=13month, clear month
	incf INDF ; month default at 1
	decf FSR, f ; now FSR has address of year byte
	incf INDF, f ; +1year
	return
;*******************************************************************************
; "divfn": Byte Integer Division Function
; Func: Devide temp by W and store result in W, not efficient
; Input: Temp = Dividend, W = Dividor
; Output: W = Quotient, arith_temp = reminder,
; set STATUS Z for zero quotient, C for error
; Affect: arith_temp2
;*******************************************************************************
divfn
	addlw 0x00
	bsf STATUS, C ; set carry in case of error
	btfsc STATUS, Z ; if zero
	return ; return (error C,Z)
	clrf arith_temp2
divfn_loop
	subwf arith_temp, f
	btfss STATUS, C
	goto divfn_next
	incf arith_temp2, f
	goto divfn_loop
divfn_next
	addwf arith_temp, f
	movf arith_temp2, w
	return
;*******************************************************************************
; "mulfn": Byte Integer Multiplication Function
; Func: Multiple W by temp and return result in W, not efficient
; Input: Temp, W
; Output: W = Result, set STATUS Z for zero, C for overflow
; Affect: arith_temp, arith_temp2
;*******************************************************************************
mulfn
	bcf STATUS, C ; clr C bit for arith_temp == 0
	movwf arith_temp2 ; store W in arith_temp2
	movlw 0x00 ; W = 0 + arith_tempp * arith_temp2
	movf arith_temp, f
	btfsc STATUS, Z
	return ; arith_temp == 0, return 0
mulfn_loop
	addwf arith_temp2, w
	btfsc STATUS, C
	goto mulfn_overflow ; W>255 overflow
	decfsz arith_temp, f
	goto mulfn_loop
mulfn_overflow
	return
	end