;
; led.asm
;
; Created: 15/09/2017 3:19:01 PM
; Author : Liangde Li z5077896 Dankoon Yoo z5116090
;

; wire PC0-3 to LED0-3, PB0-1 to PF0-1 

.include "m2560def.inc"
.def temp =r16

.cseg
.org 0x0
ldi r17, 1
ldi r21, 0
ser temp ; temp = 0xFF
out PORTC, temp ; Write ones to all the LEDs
out DDRC, temp ; PORTC is all outputs
out PORTF, temp ; Enable pull-up resistors on PORTF
clr temp
out DDRF, temp ; PORTF is all inputs
ldi temp, 0xFF
switch0:
sbic PINF, 0 ; Skip the next instruction if PB0 is pushed
rjmp switch1 ; If not pushed, check the other switch
sub temp, r17
out PORTC, temp
ldi r18, 0x90   ;26000
ldi r19, 0x65
;ldi r20, 0x00
delay1:
sub r18, r17
sbc r19, r21
;sbc r20, r21
cp r18, r21
cpc r19, r21
;cpc r20, r21
brne delay1
switch1:
sbic PINF, 1 ; Skip the next instruction if PB1 is pushed
rjmp switch0 ; If not pushed, check the other switch
inc temp
out PORTC, temp
ldi r18, 0x90
ldi r19, 0x65
;ldi r20, 0x00
delay2:
sub r18, r17
sbc r19, r21
;sbc r20, r21
cp r18, r21
cpc r19, r21
;cpc r20, r21
brne delay2
rjmp switch0 ; Now check PB0 again

