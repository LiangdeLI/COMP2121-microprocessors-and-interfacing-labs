;
; lab01.asm
;
; Created: 11/08/2017 11:51:11 AM
; Liangde Li z5077896, Dankoon Yoo z5116090
;


.include "m2560def.inc"
.def a_byte0=r16
.def a_byte1=r17
.def b_byte0=r18
.def b_byte1=r19


.cseg
.org 0x00

ldi a_byte0, low(2100)
ldi a_byte1, high(2100)
ldi b_byte0, low(1200)
ldi b_byte1, high(1200)

for:
cp a_byte0, b_byte0
cpc a_byte1, b_byte1
breq loopforever

cp a_byte0, b_byte0
cpc a_byte1, b_byte1
brlo less
sub a_byte0, b_byte0
sbc a_byte1, b_byte1
rjmp for

less:sub b_byte0, a_byte0
sbc b_byte1, a_byte1
rjmp for
loopforever:rjmp loopforever


