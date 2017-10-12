;
; cs2121Lab04.asm
;
; Created: 6/10/2017 2:45:12 PM
; Author : Liangde Li z5077896 Dankoon Yoo z5116090
;

; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
; 2. Connect the four LCD control pins BE-RS to PORTA4-7.
  
.include "m2560def.inc"
.equ PATTERN = 0b11110000 
 .def temp = r21
 .def mins_1 = r17
 .def mins_0 = r22
 .def secd_1 = r18
 .def secd_0 = r23
 .def mask = r19
 .equ START_TIME = 0b00000000 ;

  .macro clear
 ldi YL, low(@0) ; load the memory address to Y pointer
 ldi YH, high(@0)
 clr temp ; set temp to 0
 st Y+, temp ; clear the two bytes at @0 in SRAM
 st Y, temp
 .endmacro

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro display
    ldi r20, 48
    add r16, r20
	rcall lcd_data
	rcall lcd_wait
.endmacro

.dseg
SecondCounter: .byte 2 ; two-byte counter for counting seconds.
TempCounter: .byte 2 ; temporary counter used to determine if one second has passed
.cseg
.org 0x0000
	
jmp RESET
jmp DEFAULT ; no handling for IRQ0.
jmp DEFAULT ; no handling for IRQ1.
.org OVF0addr ; OVF0addr is the address of Timer0 Overflow Interrupt Vector
jmp Timer0OVF ; jump to the interrupt handler for Timer0 overflow.
jmp DEFAULT ; default service for all other interrupts.
DEFAULT: reti ; no interrupt handling 

RESET:
    ldi secd_1, 0
	ldi secd_0, 0
    ldi mins_1, 0
	ldi mins_0, 0
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

 rjmp main ; jump to main program
	

Timer0OVF: ; interrupt subroutine to Timer0
 in temp, SREG
 push temp ; prologue starts
 push YH ; save all conflicting registers in the prologue
 push YL
 push r25
 push r24 ; prologue ends
 ; Load the value of the temporary counter
 lds r24, TempCounter
 lds r25, TempCounter+1
 adiw r25:r24, 1 ; increase the temporary counter by one
 cpi r24, low(7812) ; check if (r25:r24) = 7812
 ldi temp, high(7812) ; 7812 = 106/128
 cpc r25, temp
 brne NotSecond
 
 rjmp end_calculation;calculate_value

 NotSecond: ; store the new value of the temporary counter
 sts TempCounter, r24
 sts TempCounter+1, r25

 EndIF: pop r24 ; epilogue starts
 pop r25 ; restore all conflicting registers from the stack
 pop YL
 pop YH
 pop temp
 out SREG, temp
 reti ; return from the interrupt

 end_calculation:
    do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
  mov r16, mins_1 
  display
  mov r16, mins_0
  display
  do_lcd_data ':'
  mov r16, secd_1
  display
  mov r16, secd_0
  display

  inc secd_0
  cpi secd_0, 10
  brne go_on
  ldi secd_0, 0
  inc secd_1
  cpi secd_1, 6
  brne go_on
  ldi secd_1, 0
  inc mins_0
  cpi mins_0, 10
  brne go_on
  ldi mins_0, 0
  inc mins_1
  go_on:
 clear TempCounter ; reset the temporary counter
 ; Load the value of the second counter
 lds r24, SecondCounter
 lds r25, SecondCounter+1
 adiw r25:r24, 1 ; increase the second counter by one
 sts SecondCounter, r24
 sts SecondCounter+1, r25
 rjmp EndIF


.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	nop
	nop
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
    nop
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret


 main: 
 clear TempCounter ; initialize the temporary counter to 0
 clear SecondCounter ; initialize the second counter to 0
 ldi temp, 0b00000000
 out TCCR0A, temp
 ldi temp, 0b00000010
 out TCCR0B, temp ; set prescalar value to 8
 ldi temp, 1<<TOIE0 ; TOIE0 is the bit number of TOIE0 which is 0
 sts TIMSK0, temp ; enable Timer0 Overflow Interrupt
 sei ; enable global interrupt
 end_loop: 
 rjmp end_loop ; loop forever