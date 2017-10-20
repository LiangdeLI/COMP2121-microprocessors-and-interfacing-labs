/*
 * TaskB.asm
 *
 *  Created: 20/10/2017 10:11:17 AM
 *   Author: Liangde Li z5077896 Dankoon Yoo z5116090
 */ 

 .include "m2560def.inc"

.def temp = r16
.def temp1 = r17
.def flag = r24



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
; The macro clears a word (2 bytes) in a memory
; the parameter @0 is the memory address for that word
.macro clear_2
    ldi YL, low(@0)     ; load the memory address to Y
    ldi YH, high(@0)
    clr temp 
    st Y+, temp         ; clear the two bytes at @0 in SRAM
    st Y, temp
.endmacro
                        
.dseg
SecondCounter:
   .byte 2              ; Two-byte counter for counting seconds.
TempCounter:
   .byte 2              ; Temporary counter. Used to determine 
                        ; if one second has passed
.cseg
.org 0x0000
jmp RESET
.org INT0addr ; INT0addr is the address of EXT_INT0
jmp EXT_INT0
.org INT1addr ; INT1addr is the address of EXT_INT1
jmp EXT_INT1
.org OVF3addr
jmp Timer3OVF ; Jump to the interrupt handler for
                        ; Timer3 overflow.
jmp DEFAULT          ; default service for all other interrupts.
DEFAULT:  reti          ; no service


RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp
ser r16
out DDRF, r16
out DDRA, r16
clr r16
out PORTF, r16
out PORTA, r16

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

do_lcd_data 'H'
do_lcd_data 'e'
do_lcd_data 'l'
do_lcd_data 'l'
do_lcd_data 'o'
do_lcd_data '1'
do_lcd_data '2'
do_lcd_data '3'

clr temp
out DDRD, temp
out PORTD, temp
ldi temp, (2 << ISC10) | (2 << ISC00)
sts EICRA, temp
in temp, EIMSK
ori temp, (1<<INT0) | (1<<INT1)
out EIMSK, temp

clr temp 							
sts TCCR1A, temp
ldi temp1, (1 << CS12)	; set prescaler to 256
sts TCCR1B, temp

sei
jmp main



EXT_INT0:
push temp
in temp, SREG
push temp
cpi flag, 1
brne real_int0
clr flag
pop temp
out SREG, temp
pop temp
reti
real_int0:
lds temp, TargetSpeed
cpi temp, 0
lds temp, TargetSpeed + 1
ldi temp1, 0
cpc temp1, temp2
breq LEFT_BUTTON_Flag
pop temp
out SREG, temp
pop temp
reti



EXT_INT1:
push temp
in temp, SREG
push temp
cpi flag, 1
brne real_int1
clr flag
pop temp
out SREG, temp
pop temp
reti
real_int1:
; to do for push button 1
pop temp
out SREG, temp
pop temp
reti



Timer3OVF: ; interrupt subroutine to Timer3
in temp, SREG
push temp       ; Prologue starts.
push YH         ; Save all conflict registers in the prologue.
push YL
push r25
push r24
push r20
push r19

newSecond:
	lds r24, TempCounter
    lds r25, TempCounter+1
    adiw r25:r24, 1 ; Increase the temporary counter by one.

    cpi r24, low(7812)  ; Check if (r25:r24) = 7812 
    ldi temp, high(7812)   
    cpc r25, temp
    brne NotSecond

rjmp EndIF
    


NotSecond: ; Store the new value of the temporary counter.
    sts TempCounter, r24
    sts TempCounter+1, r25 
    
EndIF:
	pop r19
	pop r20
    pop r24         ; Epilogue starts;
    pop r25         ; Restore all conflict registers from the stack.
    pop YL
    pop YH
    pop temp
    out SREG, temp
    reti            ; Return from the interrupt.



main: ; main - does nothing 
clr flag
loop: rjmp loop



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