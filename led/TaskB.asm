/*
 * TaskB.asm
 *
 *  Created: 22/09/2017 2:27:22 AM
 *   Author: Liangde Li z5077896 Dankoon Yoo z5116090
 */ 

 .include "m2560def.inc"
.def temp =r16
.def led = r22
.def flag = r24
.cseg
.org 0x0
jmp RESET
.org INT0addr ; INT0addr is the address of EXT_INT0
jmp EXT_INT0
.org INT1addr ; INT1addr is the address of EXT_INT1
jmp EXT_INT1

RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp
ser temp
out DDRC, temp
ldi led, 0xFF
out PORTC, temp
clr temp
out DDRD, temp
out PORTD, temp
ldi temp, (2 << ISC10) | (2 << ISC00)
sts EICRA, temp
in temp, EIMSK
ori temp, (1<<INT0) | (1<<INT1)
out EIMSK, temp
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
ldi r17, 0b10000
ldi r21, 0
ldi r23, 1
sub led, r17
out PORTC, led
ldi flag, 1
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
ldi r17, 0b10000
ldi r21, 0
ldi r23, 1
add led, r17
out PORTC, led
ldi flag, 1
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

main: ; main - does nothing but increment a counter
clr temp
clr flag
loop:
inc temp
rjmp loop