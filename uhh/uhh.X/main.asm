    list p=16f877
    #include <p16f877.inc>
    #include <common.inc>
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF
    extern LCD_init, LCD_clear, LCD_line2, LCD_out, LCD_wt
	extern delay50us, delayX50usm, delay5ms, delayX5msm, delay100ms, delayX100msm, delay1sl
    extern run_expat1, run_expat2, run_expat3, run_expat4, run_expat5, run_expat6, run_eexpat1, run_eexpat2, run_eexpat3, run_eexpat4, run_eexpat5, run_eexpat6
;******************VARIABLES****************************************************
    cblock 0x20
        arg ;used in COPY_DEC1
        arg2 ;used in COPY_DEC1
        arith_temp ;contains remainder/divident, or multiplier
        arith_temp2 ;contains quotient of divfn, or multiplier
        layout : .20
        LCDline : .17 ;?????
        line_num
        literal_addr
        log_total ;total number of reports
        log_next ;index for next report
        newsec
        phase
        report_num
        temp ;used in literal and copylayout
        temp2
        temp3
        temp4
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
        pat1
        pat2
        redr
        camelr
        fs_1
        fs_2
    endc
    cblock 0xB0

    endc

    udata_shr
w_temp res 1
status_temp res 1
FSR_temp res 1
rt_counter res 1
table_temp res 1
;**********************MACROS**********************************
DIVLW macro L
    movwf arith_temp ;store the divident
    movlw L ;move divisor into w
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

STORE_FORCE macro addr
    movlw addr
    call forcesensor
endm

DELAY_2500MS macro
    movlw .5
    call delayX100msm
    call delay1sl
    call delay1sl
endm

DELAY_1800MS macro
    movlw .8
    call delayX100msm
    call delay1sl
endm
;****************************
    org 0x0000
    goto main

    org 0x0004
    goto interrupt

    org 0x0005
literal
    movwf temp ;w originally contains literal_addr
    clrf PCLATH
    movf temp, w
    movwf PCL
str_init dt "INITIALIZING...", 0
str_noreport dt "NO REPORT", 0
str_enterymd dt "ENTER 20YYMMDD", 0
str_enterhms dt "ENTER hhmmss", 0
str_yearhead dt "20", 0
str_dash dt "-", 0
str_colon dt ":", 0
str_entry dt "LOG ENTRY: ",0
str_start dt "START: ", 0
str_finish dt "FINISH: ", 0
str_runtime dt "RUNTIME: ", 0
str_s dt "s", 0 ; i.e. second
str_redr dt "RED: ", 0
str_camelr dt "CAMEL: ", 0
str_running dt "RUNNING", 0
str_dot dt ".", 0
str_insp_fin dt "INSPECTION FIN", 0
str_pat1 dt "PAT 1: ", 0
str_pat2 dt "PAT 2: ", 0
str_emerstop dt "EMERGENCY STOP", 0
str_null dt 0
; corresponds to the layout byte
; corresponds to keypad
char_keynumber dt "123", 0, "456", 0, "789", 0, 0, "0", 0, 0
char_slash dt "/", 0

main
    call init
keypoll
	btfsc KEYPAD_DA ;Keypad data available pin PORTB, 1
	call keyresp
    call keypad_timeout
	goto keypoll

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
	;bcf IRLED ; turn off IRLEDs
	MOVLF FSR, LCDline ; display emergency stop
	COPY_STRING str_emerstop
	call LCD_clear ; clear LCD display
	call writeline
	call LCD_out
    bcf PORTC, 0
    bcf PORTC, 2
    bcf PORTC, 1
    bcf PORTC, 3
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

init
    call init_pic
    call reset_software
    call reset_hardware
    call reset_realtime
    clrf TMR0 ; start timing
	bsf INTCON, T0IE
	bsf INTCON, GIE
	movlw PHASE_REALTIME
	movwf phase
	call display
    return

init_pic
    clrf INTCON ;Disable interrupt
    BANK0
    clrf TMR0
    clrf rt_counter
    BANK1
    movlw INITVAL_OPTREG
    movwf OPTION_REG
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
    movlw INITVAL_ADCON1
	movwf ADCON1
	BANK0
	movlw INITVAL_ADCON0
	movwf ADCON0
	return

;*********reset_software*****
reset_software
    movlw PHASE_HDINIT
	movwf phase
	clrf report_num
	clrf line_num
	clrf log_total
	clrf log_next
	return
;****************************
;********reset_hardware******
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
    return
;****************************
;******reset_realtime********
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
;****************************
;*********addsec*************
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
;****************************
;*********addday*************
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
;****************************
;*******calcruntime**********
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
;****************************
;*********copydec************
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
;****************************
;*************copystring**************
copystring
    movwf literal_addr ;copy w (containing the string address) into literal_addr
copystring_loop
    movf literal_addr, w
    call literal
    movwf INDF
    movf INDF, f ;test INDF(last char) == 0 (end of string)
    btfsc STATUS, Z
    return ;return if end of string is reached
    incf FSR, f
    incf literal_addr, f
    goto copystring_loop
;****************************
;*********display************
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
;****************************
;*********divfn**************
divfn
    addlw 0x00 ;w contains the divisor
    bsf STATUS, C ;set carry bit in STATUS in case of error
    btfsc STATUS, Z ;if zero
    return ;return with error
    clrf arith_temp2 ;else, arith_temp2 contains the result
divfn_loop
    subwf arith_temp, f ;arith_temp - w
    btfss STATUS, C ;check carry
    goto divfn_next ;if carry is zero, goto next
    incf arith_temp2, f ;if carry is not zero, increment quotient, which is in arith_temp2
    goto divfn_loop
divfn_next
    addwf arith_temp, f ;undo the last one
    movf arith_temp2, w ;w now contains the quotient
    return
;****************************
;********forcesensor*********
forcesensor
    clrf redr
    movlw st_sec
    MODLW .5
    movwf redr
    ;movlw st_min
    ;MODLW .3
    ;MULLW redr
    ;movwf redr

    clrf camelr
    movlw end_sec
    MODLW .5
    movwf camelr
    ;movlw end_min
    ;MODLW .3
    ;MULLW camelr
    ;movwf camelr
    return
;****************************
;*********keyresp************
keyresp
	swapf PORTB, w
	andlw 0x0F
	TABLE
    ;keyresp_switch_table
	goto unused_key ; keypressed = 0 "1" = "real time"
	goto unused_key ; keypressed = 1 "2" = "report"
	goto unused_key ; keypressed = 2 "3"
	goto realtime ; keypressed = 3 "A"
	goto unused_key ; keypressed = 4 "4"
	goto unused_key ; keypressed = 5 "5"
	goto unused_key ; keypressed = 6 "6"
	goto report ; keypressed = 7 "B"
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
initrun
	call LCD_clear ; clear LCD display
	MOVLF FSR, LCDline
	COPY_STRING str_pat1
	call writeline
	clrf temp3 ; number of valid numbers entered
initrun_pat
	btfss KEYPAD_DA ; Wait until data is available from the keypad
	goto initrun_pat
	swapf PORTB, W ; Read PortB<7:4> into W<3:0>
	andlw 0x0F
	addlw char_keynumber
	call literal ; Convert keypad value to LCD character (value is still held in W)
	addlw 0x00
	btfsc STATUS, Z ; test for valid input (number)
	goto initrun_pat1rl
	movwf temp2 ; hold the value
	call LCD_wt ; Write the value in W to LCD
	movlw 0x30
	subwf temp2, f ; convert ASCII to number
	movf temp3, w
initrun_pat1
	movf temp2, w
	movwf pat1
	incf temp3, f
initrun_pat1rl
	btfsc KEYPAD_DA ; Wait until key is released
	goto initrun_pat1rl
	movlw 0x01 ; 1 chars entered
	subwf temp3, w
	btfss STATUS, C
	goto initrun_pat
	; pat2
	;call LCD_clear ; clear LCD display
	MOVLF FSR, LCDline
	call LCD_line2
	COPY_STRING str_pat2
	call writeline
	;call LCD_line2
	clrf temp3 ; number of valid numbers entered
initrun_patt
	btfss KEYPAD_DA ; Wait until data is available from the keypad
	goto initrun_patt
	swapf PORTB, W ; Read PortB<7:4> into W<3:0>
	andlw 0x0F
	addlw char_keynumber
	call literal ; Convert keypad value to LCD character (value is still held in W)
	addlw 0x00
	btfsc STATUS, Z ; test for valid input (number)
	goto initrun_pat2rl
	movwf temp2 ; hold the value
	call LCD_wt ; Write the value in W to LCD
	movlw 0x30
	subwf temp2, f ; convert ASCII to number
	movf temp3, w
initrun_pat2
	movf temp2, w
	movwf pat2
	incf temp3, f
initrun_pat2rl
	btfsc KEYPAD_DA ; Wait until key is released
	goto initrun_pat2rl
	movlw 0x01 ; 1 chars entered
	subwf temp3, w
	btfss STATUS, C
	goto initrun_patt
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
;****************************
;********keypad_timeout******
keypad_timeout
	movf newsec, f
	btfsc STATUS, Z
	goto kp_to_nonewsec ; newsec == 0(FALSE), skip
	call display ; newsec == TRUE, display the new sec
	clrf newsec
kp_to_nonewsec
; SLEEP test goes here!!!!
	return
;****************************
;***********makeline*********
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
	COPY_STRING str_pat1
	COPY_DEC1 pat1
	return
ML_report_5
	COPY_STRING str_pat2
    COPY_DEC1 pat2
	return
ML_report_6
    COPY_STRING str_redr
    COPY_DEC1 redr
    return
ML_report_7
    COPY_STRING str_camelr
    COPY_DEC1 camelr
    return
ML_report_8
    COPY_STRING str_null
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
;****************************
;***********mulfn************
mulfn
    bcf STATUS, C ;clear C bit if arith_temp==0
    movwf arith_temp2 ;the multiplier L is stored in arith_temp2
    movlw 0x00
    movf arith_temp, f ; check if arith_temp is 0, changes Z bit in STATUS
    btfsc STATUS, Z
    return ; if arith_temp is zero, return
mulfn_loop
    addwf arith_temp2, w ; w=0+arith_temp2+arith_temp2+...
    btfsc STATUS, C
    goto mulfn_overflow
    decfsz arith_temp, f
    goto mulfn_loop
mulfn_overflow
    return
;****************************
;*********readlog************
readlog
    readlog
	movwf temp2 ; save the index in temp2
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
    MOVFF pat1, INDF
	incf FSR, f ; log addr + 7
	MOVFF pat2, INDF
	incf FSR, f ; log addr + 8
    MOVFF redr, INDF
    incf FSR, f
    MOVFF camelr, INDF
    incf FSR, f
	 ; read layout[], cl_total and cl_pass
	MOVFF temp, FSR ; the address of log entry (start at + 6)
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
	bcf STATUS, IRP ; back to BANK0&1 indirect access
	return
;****************************
;*********run************
run
    ; store sarting time
	MOVFF st_year, rt_year
	MOVFF st_month, rt_month
	MOVFF st_day, rt_day
	MOVFF st_hour, rt_hour
	MOVFF st_min, rt_min
	MOVFF st_sec, rt_sec
    ; Main operation goes below
run_loop
    bcf INTCON, RBIF
	bsf INTCON, RBIE ; enable keypad interrept
run_hardware_bottom_motor
rs_hardware_loop
    bcf PORTC, 1
    bsf PORTC, 3
    pagesel delay5ms
    ;call delay5ms
    movlw .30
    call delayX50usm
    bcf PORTC, 3
    call delay5ms
    pagesel rs_hardware_loop
    btfss PORTC, 5
    goto rs_hardware_loop
    clrf PORTC
    ;movlw B'10000000'
    ;movwf TRISC
    bcf PORTC, 1
    bcf PORTC, 3
run_sequence1
    pagesel run_expat1
    movlw .1
    subwf pat1, w
    btfsc STATUS, Z
    call run_expat1
    pagesel run_expat2
    movlw .2
    subwf pat1, w
    btfsc STATUS, Z
    call run_expat2
    pagesel run_expat3
    movlw .3
    subwf pat1, w
    btfsc STATUS, Z
    call run_expat3
    pagesel run_expat4
    movlw .4
    subwf pat1, w
    btfsc STATUS, Z
    call run_expat5
    pagesel run_expat5
    movlw .5
    subwf pat1, w
    btfsc STATUS, Z
    call run_expat4
    pagesel run_expat6
    movlw .6
    subwf pat1, w
    btfsc STATUS, Z
    call run_expat6
    ; bsf PORTC, 1 = cw
    ; bsf PORTC, 3 = ccw

; asdf
    ; goto asdf
    pagesel delayX100msm
    movlw .5
    call delayX100msm
    pagesel asdf
asdf
    bcf PORTC, 1
    bsf PORTC, 3
    pagesel delay5ms
    call delay5ms
    ;movlw .40
    ;call delayX50usm
    bcf PORTC, 3
    call delay5ms
    pagesel asdf
    btfss PORTC, 5
    goto asdf
    pagesel run_sequence1
    clrf PORTC
    ;movlw B'10000000'
    ;movwf TRISC
    bcf PORTC, 1
    bcf PORTC, 3

    nop
    pagesel run_eexpat1
    movlw .1
    subwf pat2, w
    btfsc STATUS, Z
    call run_eexpat1
    pagesel run_eexpat2
    movlw .2
    subwf pat2, w
    btfsc STATUS, Z
    call run_eexpat2
    pagesel run_eexpat3
    movlw .3
    subwf pat2, w
    btfsc STATUS, Z
    call run_eexpat3
    pagesel run_eexpat4
    movlw .4
    subwf pat2, w
    btfsc STATUS, Z
    call run_eexpat5
    pagesel run_eexpat5
    movlw .5
    subwf pat2, w
    btfsc STATUS, Z
    call run_eexpat4
    pagesel run_eexpat6
    movlw .6
    subwf pat2, w
    btfsc STATUS, Z
    call run_eexpat6

    
    pagesel delay1sl
    call delay1sl
    ;call delay1sl
    pagesel delay1sl
    bcf PORTC, 1
    bsf PORTC, 3
    movlw .5
    call delayX100msm
    call delay1sl
    ;call delay1sl
    bcf PORTC, 3
run_countchips
    STORE_FORCE fs_1
    STORE_FORCE fs_2
run_end
	bcf INTCON, RBIE ; disable keypad interrept
	; store end time
	MOVFF end_hour, rt_hour
	MOVFF end_min, rt_min
	MOVFF end_sec, rt_sec
	call calcruntime
	call writelog
	movwf report_num
	return
;****************************
;*********writeline**********
writeline
	MOVLF FSR, LCDline
writeline_loop
	movf INDF, w ; test INDF(char pointer to the string)==0(NULL)
	btfsc STATUS, Z
	return ; if end of string is reached (NULL)
	call LCD_wt
	incf FSR, f
	goto writeline_loop
;****************************
;********writelog************
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
    MOVFF INDF, pat1
	incf FSR, f ; log addr + 7
    MOVFF INDF, pat2
	incf FSR, f ; log addr + 8
    MOVFF INDF, redr
    incf FSR, f
    MOVFF INDF, camelr
    incf FSR, f
	; store layout
	MOVFF temp, FSR ; the address of log entry (start at + 8)
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
;****************************
    end