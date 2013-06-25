    #include <p16f877.inc>
    #include <common.inc>
    extern delay50us, delay5ms, delayX5msm, delay100ms, delayX100msm, delay1sl
    global run_expat1, run_expat2, run_expat3, run_expat4, run_expat5, run_expat6, run_eexpat1, run_eexpat2, run_eexpat3, run_eexpat4, run_eexpat5, run_eexpat6

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

DELAY_1500MS macro
    movlw .5
    call delayX100msm
    call delay1sl
endm

page2 code 0x0800
; bsf PORTC, 0 is cw
; bsf PORTC, 2 is ccw
; right reservoir white
; left reservoir red
run_expat1
    ; all red
	bcf PORTC, 0
    bsf PORTC, 2
    pagesel delay100ms
    ;call delay100ms
    movlw .6
    call delayX100msm
	; call delay100ms
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	; call delay1sl
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
    ; call delay1sl
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
    ; call delay1sl
   	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
    ; call delay1sl
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
  	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
   	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
   	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
    bcf PORTC, 2
    bcf PORTC, 0
    
    
   	return
run_expat2
; all white
	bcf PORTC, 2
    bsf PORTC, 0
    pagesel delay100ms
    ;call delay100ms
    movlw .6
    call delayX100msm
	; call delay100ms
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
	; call delay1sl
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
    ; call delay1sl
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
    ; call delay1sl
   	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
    ; call delay1sl
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
  	movlw .10
    call delayX5msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
   	movlw .10
    call delayX5msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
   	movlw .10
    call delayX5msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
    movlw .6
    call delayX5msm
    bcf PORTC, 2
    bcf PORTC, 0

	return
run_expat3
      ; all white top all red bottom
    pagesel delay100ms
    bcf PORTC, 0
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
    bcf PORTC, 2
    ;call delay100ms
    bcf PORTC, 0

    return
run_expat4
    ; alternating two's (white top)
    pagesel delay100ms
	bcf PORTC, 0
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    bcf PORTC, 2
    bcf PORTC, 0

    return
run_expat5
    ; alternating two's (red top)
    pagesel delay100ms
	bcf PORTC, 2
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .4
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
    bcf PORTC, 2
    bcf PORTC, 0

    return
run_expat6
    ; alternating
    pagesel delay100ms
    bcf PORTC, 2
    bsf PORTC, 0
	movlw .5
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .9
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .9
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .9
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .9
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .9
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .9
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .9
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .9
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .9
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .3
    call delayX100msm
    bcf PORTC, 0
    bcf PORTC, 2

    return
; alternating

run_eexpat1
    ; all red
	bcf PORTC, 0
    bsf PORTC, 2
    pagesel delay100ms
    ;call delay100ms
    movlw .5
    call delayX100msm
	; call delay100ms
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
	; call delay1sl
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    ; call delay1sl
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    ; call delay1sl
   	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    ; call delay1sl
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
  	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
   	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
   	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .5
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .2
    call delayX100msm
    movlw .5
    call delayX5msm
    bcf PORTC, 2
    bcf PORTC, 0
    return
run_eexpat2
    ; all white
    bcf PORTC, 2
    bsf PORTC, 0
    pagesel delay100ms
    ;call delay100ms
    movlw .6
    call delayX100msm
	; call delay100ms
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	; call delay1sl
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    ; call delay1sl
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    ; call delay1sl
   	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
    ; call delay1sl
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
  	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
   	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
   	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .1
    call delayX100msm
    ;movlw .10
    ;call delayX5msm
    bcf PORTC, 2
    bcf PORTC, 0
	return
run_eexpat3
    ; all white top all red bottom
    pagesel delay100ms
    bcf PORTC, 0
    bsf PORTC, 2
	movlw .6
    call delayX100msm
    call delay100ms
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .4
    call delayX100msm
    bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .4
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .1
    call delayX100msm
    movlw .10
    call delayX5msm
    bcf PORTC, 2
    ;call delay100ms
    bcf PORTC, 0
    return
run_eexpat4
    ; alternating two's (white top)
    pagesel delay100ms
	bcf PORTC, 0
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .2
    call delayX100msm
    movlw .14
    call delayX5msm
    bcf PORTC, 2
    bcf PORTC, 0
    return
run_eexpat5
      ; alternating two's (red top)
    pagesel delay100ms
	bcf PORTC, 2
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .3
    call delayX100msm
    movlw .10
    call delayX5msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
    movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .1
    call delayX100msm
    movlw .15
    call delayX5msm
    bcf PORTC, 2
    bcf PORTC, 0
    return
run_eexpat6
    ; alternating
    pagesel delay100ms
    bcf PORTC, 2
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .3
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .3
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .2
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .2
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .2
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
	bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
	movlw .2
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 0
	movlw .6
    call delayX100msm
	bcf PORTC, 0
    call delay100ms
    bsf PORTC, 2
	movlw .2
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 2
	movlw .6
    call delayX100msm
    bcf PORTC, 2
    call delay100ms
    bsf PORTC, 0
    movlw .3
    call delayX100msm
    bcf PORTC, 0
    bcf PORTC, 2
    return

    end