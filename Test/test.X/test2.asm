#include <p16f877.inc>
#include <common.inc>
cblock 0xA0
	delaytemp
	delaycount
	delaytemp2
	delaycount2
	delaytemp3
	delaycount3
endc

code
global delay50us, delay5ms, delayX5msm, delay100ms, delayX100msm, delay1sl
;*******************************************************************************
; "dalay50us": 50us Delay Function
; Func: Precisely dalay 50 microsecond for 10Mz (125cycles*4)
; including the time this function being called
; Input: None
; Output: None
; Affect: STATUS, delaytemp, delaycount
; Runtime: 50.0 us
;*******************************************************************************
delay50us
	; call function cost 2 cycles
	;BANK1 ; 2 cycles
	bcf STATUS, RP1
	bsf STATUS, RP0
	movwf delaytemp ; protect the data in w, 1 cycle
	movlw 0x26 ; 38, 1 cycle
	movwf delaycount ; 1 cycle
delay50us_loop ; ((1+2)*38)-1 = 113 cycles
	decfsz delaycount, f
	goto delay50us_loop
	movf delaytemp, w ; resume w, 1 cycle
	;BANK0 ; 2 cycles
	bcf STATUS, RP0
	nop
	return ; 2 cycles
;*******************************************************************************
; "dalay5ms": 5ms Delay Function
; Func: Precisely dalay 5 millisecond for 10Mz (100*125cycles*4)
; including the time this function being called
; Input: None
; Output: None
; Affect: STATUS, delaytemp, delaycount, delaytemp2, delaycount2
; Runtime: 5,000.0 us
;*******************************************************************************
delay5ms
	; call function cost 2 cycles
	;BANK1 ; 2 cycles
	bcf STATUS, RP1
	bsf STATUS, RP0
	movwf delaytemp2 ; protect the data in w, 1 cycle
	; 5 cycles to this point
	movlw 0x60 ; 96, 1 cycle
	movwf delaycount2 ; 1 cycle
delay5ms_loop ; (130*96)-1 = 12479 cycles
	;call delay50us ; (125 cycles)
	nop
	 ;BANK1 ; 2 cycles
	bcf STATUS, RP1
	bsf STATUS, RP0
	movwf delaytemp ; protect the data in w, 1 cycle
	movlw 0x27 ; 39, 1 cycle
	movwf delaycount ; 1 cycle
delay5ms_50us_loop ; ((1+2)*39)-1 = 116 cycles
	decfsz delaycount, f
	goto delay5ms_50us_loop
	movf delaytemp, w ; resume w, 1 cycle
	;BANK0 ; 2 cycles
	bcf STATUS, RP0
	nop
	;BANK1 ; delay50us will reset Bank to 0, (2 cycles)
	bcf STATUS, RP1
	bsf STATUS, RP0
	decfsz delaycount2, f ; (1(2) cycle)
	goto delay5ms_loop ; (2 cycle)
	; 12486 cycles to this point
	movlw 0x02 ; 2, 1 cycle
	movwf delaycount2 ; 1 cycle
delay5ms_loop2 ; (3*2)-1 = 5 cycles
	decfsz delaycount2, f
	goto delay5ms_loop2
	; 12493 cycles to this point
	nop ; 1 cycle
	nop ; 1 cycle
	movf delaytemp2, w ; resume w, 1 cycle
	;BANK0 ; 2 cycles
	bcf STATUS, RP0
	nop
	return ; 2 cycles
;*******************************************************************************
; "dalayX5msm": Multiple of 5ms More Delay Function (less than 0.1% error)
; Func: Delay slightly more than 5*W millisecond for 10Mz
; precisely dalay (5.002*W+0.0032) ms ((12,505*W+8) cycles)
; including the time this function being called
; Input: W = numbers of 5ms to delay
; Output: None
; Affect: STATUS, delaytemp, delaycount, delaytemp2, delaycount2,
; delaycount3
; Runtime: (5,002.0*W + 3.2) us
;*******************************************************************************
delayX5msm
	; call function cost 2 cycles
	;BANK1 ; 2 cycles
	bcf STATUS, RP1
	bsf STATUS, RP0
	movwf delaycount3 ; 1 cycle
delayX5msm_loop ; (12505*W-1) cycles
	call delay5ms
	;BANK1 ; delay5ms will reset Bank to 0
	bcf STATUS, RP1
	bsf STATUS, RP0
	decfsz delaycount3, f
	goto delayX5msm_loop
	;BANK0 ; 2 cycles
	bcf STATUS, RP0
	nop
	return ; 2 cycles
;*******************************************************************************
; "dalay100ms": 100ms Delay Function
; Func: Precisely dalay 100 millisecond for 10Mz (250,004cycles)
; including the time this function being called
; Input: None
; Output: None
; Affect: STATUS, delaytemp, delaycount, delaytemp2, delaycount2
; Runtime: 100,001.6 us
;*******************************************************************************
delay100ms
	; call function cost 2 cycles
	;BANK1 ; 2 cycles
	bcf STATUS, RP1
	bsf STATUS, RP0
	movwf delaytemp2 ; protect the data in w, 1 cycle
	; 5 cycles to this point
	movlw 0xF9 ; 249, 1 cycle
	movwf delaycount2 ; 1 cycle
delay100ms_loop ; (1004*250)-1 = 249,995 cycles
	movlw 0xFA ; 250, 1 cycle
	movwf delaycount ; 1 cycle
delay100ms_loop2 ; (4*250)-1 = 999 cycles
	nop
	decfsz delaycount, f
	goto delay100ms_loop2
	decfsz delaycount2, f ; (1(2) cycle)
	goto delay100ms_loop ; (2 cycle)
	; 250,000 cycles to this point
	movf delaytemp2, w ; resume w, 1 cycle
	;BANK0 ; 1 cycles
	bcf STATUS, RP0
	return ; 2 cycles
;*******************************************************************************
; "dalayX100msm": Multiple of 100ms More Delay Function(less than 0.01% error)
; Func: Delay slightly more than 100*W millisecond for 10Mz
; precisely dalay (0.100002*W+0.0000032) s
; ((250,009*W+8) cycles)
; including the time this function being called
; Input: W = numbers of 100ms to delay
; Output: None
; Affect: STATUS, delaytemp, delaycount, delaytemp2, delaycount2,
; delaycount3
; Runtime: (100,003.6*W + 3.2) us
;*******************************************************************************
delayX100msm
	; call function cost 2 cycles
	;BANK1 ; 2 cycles
	bcf STATUS, RP1
	bsf STATUS, RP0
	movwf delaycount3 ; 1 cycle
delayX100msm_loop ; (250,009*W-1) cycles
	call delay100ms
	;BANK1 ; delay100ms will reset Bank to 0
	bcf STATUS, RP1
	bsf STATUS, RP0
decfsz delaycount3, f
	 goto delayX100msm_loop
	;BANK0 ; 2 cycles
	bcf STATUS, RP0
	nop
	return ; 2 cycles
;*******************************************************************************
; "dalay1sl": 1s Less Delay Function
; Func: Dalay slightly less than 1 second for 10Mz,
; precisely delay 999.0428ms (2,497,607 cycles)
; including the time this function being called
; Input: None
; Output: None
; Affect: STATUS, delaytemp, delaycount, delaytemp2, delaycount2,
; delaytemp3, delaycount3
; Runtime: 999,042.8 us
;*******************************************************************************
delay1sl
	; call function cost 2 cycles
	;BANK1 ; 2 cycles
	bcf STATUS, RP1
	bsf STATUS, RP0
	movwf delaytemp3 ; protect the data in w, 1 cycle
	; 5 cycles to this point
	movlw 0xC7 ; 199, 1 cycle
	movwf delaycount3 ; 1 cycle
delay1sl_loop ; (12505*199)-1 = 2,488,494 cycles
	call delay5ms ; (12500 cycles)
	;BANK1 ; delay5ms will reset Bank to 0, (2 cycles)
	bcf STATUS, RP1
	bsf STATUS, RP0
	decfsz delaycount3, f ; (1(2) cycle)
	goto delay1sl_loop ; (2 cycle)
	; 2,488,501 cycles to this point
	movlw 0x46 ; 70, 1 cycle
	movwf delaycount3 ; 1 cycle
delay1sl_loop2 ; (130*69)-1 = 9099 cycles
	call delay50us ; (125 cycles)
	;BANK1 ; delay50us will reset Bank to 0, (2 cycles)
	bcf STATUS, RP1
	bsf STATUS, RP0
	decfsz delaycount3, f
	goto delay1sl_loop2
	; 2,497,602 cycles to this point
	movf delaytemp3, w ; resume w, 1 cycle
	;BANK0 ; 2 cycles
	bcf STATUS, RP0
	nop
	return ; 2 cycles
	end
