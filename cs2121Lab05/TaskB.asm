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
.def holes = r20


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
RevCounter: .byte 2 ; revolution counter
TargetSpeed: .byte 1

.cseg
.org 0x0000
jmp RESET
.org INT0addr ; INT0addr is the address of EXT_INT0
jmp EXT_INT0
.org INT1addr ; INT1addr is the address of EXT_INT1
jmp EXT_INT1
.org INT2addr ; 
jmp EXT_INT2
.org OVF0addr
jmp Timer0OVF ; Jump to the interrupt handler for
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

clr temp
out DDRD, temp
out PORTD, temp
ldi temp, (2 << ISC20) | (2 << ISC10) | (2 << ISC00)
sts EICRA, temp
in temp, EIMSK
ori temp, (1<<INT2) | (1<<INT0) | (1<<INT1)
out EIMSK, temp


ldi temp1, 0 					
sts OCR3BH, temp1
ldi temp1, 0
sts OCR3BL, temp1
ldi temp1, 0
sts TargetSpeed, temp1

ldi temp1, (1 << CS30) 		; set the Timer3 to Phase Correct PWM mode. 
sts TCCR3B, temp1
ldi temp1, (1<< WGM30)|(1<<COM3B1)
sts TCCR3A, temp1

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
ldi flag, 1
lds temp, TargetSpeed
cpi temp, 100
breq END_BUTTON_ZERO
ldi temp1, 20
add temp, temp1
END_BUTTON_ZERO:
sts TargetSpeed, temp
ldi r23, 1
clr r21
ldi r18, 0xDB  
ldi r19, 0x7C
ldi r20, 0x03
delay1:
sub r18, r23
sbc r19, r21
sbc r20, r21
cp r18, r21
cpc r19, r21
cpc r20, r21
brne delay1
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
ldi flag, 1
lds temp, TargetSpeed
cpi temp, 0
breq END_BUTTON_ONE
ldi temp1, 20
sub temp, temp1
END_BUTTON_ONE:
sts TargetSpeed, temp
ldi r18, 0xDB   
ldi r19, 0x7C
ldi r20, 0x03
delay2:
sub r18, r23
sbc r19, r21
sbc r20, r21
cp r18, r21
cpc r19, r21
cpc r20, r21
brne delay2
pop temp
out SREG, temp
pop temp
reti



EXT_INT2:
push temp
in temp, SREG
push temp
push r23
push r22
inc holes
cpi holes, 4
brne end
clr holes
lds r22, RevCounter
lds r23, RevCounter+1
ldi temp, 1
add r22, temp
ldi temp, 0
adc r23, temp
sts RevCounter, r22
sts RevCounter+1, r23
end:
pop r22
pop r23
pop temp
out SREG, temp
pop temp
reti



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
cpi r24, low(781) ; check if (r25:r24) = 7812
ldi temp, high(781) ; 7812 = 10^6/128
cpc r25, temp
brne NotSecond

one_tenth_second:
lds r22, RevCounter
lds r23, RevCounter+1
ldi temp, 10
mul r22, temp
mov r24, r0
mov r25, r1
mul r23, temp
add r24, r0
adc r25, r1
lds r22, TargetSpeed
ldi r23, 0
cp r24, r22
cpc r25, r23
brlo less
lds r22, OCR3BL
lds r23, OCR3BH
ldi temp, 1
ldi temp1, 0
sub r22, temp
sbc r23, temp1
sts OCR3BL, r22
sts OCR3BH, r23
less:
lds r22, OCR3BL
lds r23, OCR3BH
ldi temp, 1
ldi temp1, 0
add r22, temp
adc r23, temp1
sts OCR3BL, r22
sts OCR3BH, r23
ldi r22, 0
ldi r23, 0
sts RevCounter, r22
sts RevCounter+1, r23
clear_2 TempCounter ; reset the temporary counter
; Load the value of the second counter
lds r24, SecondCounter
lds r25, SecondCounter+1
adiw r25:r24, 1 ; increase the second counter by one
sts SecondCounter, r24
sts SecondCounter+1, r25
rjmp EndIF
 
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
    



main: ; main - does nothing 
clr flag
ldi temp, 0b00000000
out TCCR0A, temp
ldi temp, 0b00000010
out TCCR0B, temp ; set prescalar value to 8
ldi temp, 1<<TOIE0 ; TOIE0 is the bit number of TOIE0 which is 0
sts TIMSK0, temp ; enable Timer0 Overflow Interrupt
sei ; enable global interrupt
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