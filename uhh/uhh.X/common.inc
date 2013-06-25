	;extern LCD_init, LCD_clear, LCD_line2s, LCD_out, LCD_wt, delay50us, delay5ms, delayX5msm, delay100ms, delayX100msm, delay1sl


	#define DEBUG
	#define NULL 0x00 ; must not change
	#define FALSE 0x00 ; must not change
	#define TRUE 0xFF ; must not change
	#define KEYPAD_DA PORTB, 1
	#define SMOTOR_S0 PORTD, 0
	#define SMOTOR_S1 PORTD, 1
	#define SMOTOR_S2 PORTE, 0
	#define SMOTOR_S3 PORTE, 1
	#define SMOTOR_EN PORTE, 2
	#define PMOTOR PORTC, 1
    #define SWMOTOR PORTC, 0
    #define VMOTOR_C0 PORTC, 2
	#define VMOTOR_C1 PORTC, 3
	;#define IRLED PORTC, 2
	;#define FB_TOP PORTC, 5
	;#define FB_BOT PORTC, 6
	#define FB_ROW4 PORTC, 7
	#define LCD_RS PORTD, 2
	#define LCD_E PORTD, 3
	#define LCD_PORT PORTD
	#define CL_POS_BIT 0
	#define CL_FN_BIT 1
	#define CL_ERR_BIT 2
	#define STOP_BUT 0x0B ; stop buttom
	#define PHASE_HDINIT 0 ; Phase 0: Hardware Initialization/Reset
	#define PHASE_RTCINIT 1 ; Phase 1: RTC Initialization/Reset
	#define PHASE_REALTIME 2 ; Phase 2: Real Time
	#define PHASE_NOREPORT 3 ; Phase 3: No Report
	#define PHASE_REPORT 4 ; Phase 4: Report Review
	#define PHASE_RUN 5 ; Phase 5: Inspection Run
	#define PHASE_FINISH 6 ; Phase 6: Inspection Finish
	; pull-up diable, Timer0 internal clk, pos edge, 1:64
	#define INITVAL_OPTREG B'10000101'
	#define INITVAL_TRISA B'00101111'
	#define INITVAL_TRISB B'11110010'
	#define INITVAL_TRISC B'11100000' ;B'11100000'!!!!
	#define INITVAL_TRISD B'00000000'
	#define INITVAL_TRISE B'00000000'
	#define INITVAL_ADCON0 B'10000001' ; 32Tosc, AN0, ADC on
	#define INITVAL_ADCON1 B'00000100' ; left justified, 3 channel, 0 Vref, RA0, RA1, RA3
;******************CONSTANTS****************************************************
MAXLINE EQU .6 ; (max "line_num" - 1) in report phase
MAXPOS EQU .20 ; total positions = ROWS*COLS
ROWS EQU .4 ; total 4 rows to move
COLS EQU .5 ; total 5 cols in a row
FSNUM EQU .2 ; number of force sensors
MAXCLINROW EQU .3 ; max number of CLs possible in a row
DCDOWNDELAY EQU .30 ; * 0.1s == elapse time for DC motor to drive down
SMOTOR_STEPS EQU .28 ; * 4 == # of steps that stepper motor need to turn
SMOTOR_SPD_F EQU .6 ; speed fact: speed = 1 step / (SMOTOR_SPD_F * 5ms)
THD_CL3LED EQU .80 ; threshold to distinguish between 2 LEDs and 3LEDS
THD_IRLED EQU .28 ; threshold for infrared reflected light
THD_BG EQU .5 ; threshold for background variation (add to light_bg)
MAXLOG EQU .12 ; max number of log
MAXLOGBANK EQU .6 ; max number of log per bank = MAXLOG/2
LOGLENGTH EQU .16 ; length of each log entry
LIGHTAVGX EQU .4 ; number of sample light sensor reading to be averaged
;******************MACROS*******************************************************
BANK0 macro
	bcf STATUS, RP0
	endm
BANK1 macro
	bsf STATUS, RP0
	endm
BANK00 macro
	bcf STATUS, IRP
	bcf STATUS, RP1
	bcf STATUS, RP0
	endm
	;BANK02 macro
	; bsf STATUS, IRP
	; bsf STATUS, RP1
	; bcf STATUS, RP0
	; endm
	;
	;BANK03 macro
	; bsf STATUS, IRP
	; bsf STATUS, RP1
	; bsf STATUS, RP0
	; endm
	; Affect W!
MOVFF macro dest, orig
	movf orig, w
	movwf dest
	endm
; Affect W!
MOVLF macro dest, literal
	movlw literal
	movwf dest
	endm

FCALL macro subroutine
    local here
    lcall subroutine
    pagesel here
here:
    endm