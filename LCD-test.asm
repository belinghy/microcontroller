;**************************************
; Test LCD
; Hardware  : CP-PIC877 V1.0 & V2.0
; Assembler : mpasm.exe
; Programmer: Somkiat Siha
; Company   : ETT  CO.,LTD.
; Date      : 5/2/2000
;**************************************

     list p=16f877                 ; list directive to define processor
     #include <p16f877.inc>        ; processor specific variable definitions

     __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _XT_OSC & _WRT_ENABLE_ON & _LVP_ON & _DEBUG_OFF & _CPD_OFF

#define   RS        PORTD,0        ; for v 1.0 used PORTD.3
#define   E         PORTD,1        ; for v 1.0 used PORTD.2

com       EQU       0x20           ; buffer for Instruction
dat       EQU       0x21           ; buffer for data
count1    EQU       0x22
count2    EQU       0x23
count3    EQU       0x24


          ORG       0x0000

;************ initial *******************

init      call      delay
          call      delay
          bsf       STATUS,RP0     ; select bank 1
          clrf      TRISD          ; All port D is output
          bcf       STATUS,RP0     ; select bank 0

          movlw     B'00110011'    ; 
          call      WR_INS
          movlw     B'00110010'
          call      WR_INS
          movlw     B'00101000'    ; 4 bits, 2 lines,5X7 dot 
          call      WR_INS
          movlw     B'00001100'    ; display on/off
          call      WR_INS
          movlw     B'00000110'    ; Entry mode
          call      WR_INS
          movlw     B'00000001'    ; Clear ram
          call      WR_INS

          movlw     "C"
          call      WR_DATA
          movlw     "P"
          call      WR_DATA
          movlw     "-"
          call      WR_DATA
          movlw     "P"
          call      WR_DATA
          movlw     "I"
          call      WR_DATA
          movlw     "C"
          call      WR_DATA
          movlw     "8"
          call      WR_DATA
          movlw     "7"
          call      WR_DATA
          movlw     "7"
          call      WR_DATA
dd        goto      dd

;****************************************
; Write command to LCD
; Input  : W
; output : -
;****************************************
WR_INS    bcf       RS        ; clear RS
          movwf     com       ; W --> com
          andlw     0xF0      ; mask 4 bits MSB  W = X0
          addlw     2
          movwf     PORTD     ; Send 4 bits MSB
          bcf       E         ; 
          call      delay     ; __    __      
          bsf       E         ;   |__|
          swapf     com,w
          andlw     0xF0      ; 1111 0010
          addlw     2
          movwf     PORTD     ; send 4 bits LSB
          bcf       E         ;
          call      delay     ; __    __      
          bsf       E         ;   |__|
          call      delay
          return

;***************************************
; Write data to LCD
; Input  : W
; Output : -
;***************************************
WR_DATA   bsf       RS
          movwf     dat
          movf      dat,w
          andlw     0xF0
          addlw     3
          movwf     PORTD
          bcf       E         
          call      delay     ; __    __
          bsf       E         ;   |__|
          swapf     dat,w
          andlw     0xF0
          addlw     3
          movwf     PORTD
          bcf       E         ; 
          call      delay     ; __    __
          bsf       E         ;   |__|
          return

;***************************************
; Delay 
;***************************************
delay     movlw     2
          movwf     count1
del1      clrf      count2
del2      decfsz    count2
          goto      del2
          decfsz    count1
          goto      del1
          return
          END
