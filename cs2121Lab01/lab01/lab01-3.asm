;
; lab01-2.asm
;
; Created: 16/08/2017 10:26:47 PM
; Author : Liangde Lee, Dankoon Yoo
;


.include"m2560def.inc"
.def i=r20
.def sum_byte0=r5
.def sum_byte1=r6

.dseg
.org 0x200
sum:.byte 2

.cseg
.org 0x00
clr sum_byte0
clr sum_byte1

ldi yl, low(sum)
ldi yh, high(sum)

clr i
clr r0
clr r1
ldi r21, 200

for1: 
mul r21, i
add r9, r0
adc r10, r1
inc i
cpi i, 10
brlo for1

mov sum_byte1, r10
mov sum_byte0, r9

st y+, sum_byte0
st y, sum_byte1

loopforever:rjmp loopforever
