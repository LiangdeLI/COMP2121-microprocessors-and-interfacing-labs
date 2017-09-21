;
; lab01-2.asm
;
; Created: 11/08/2017 12:38:58 PM
; Liangde Li z5077896, Dankoon Yoo z5116090
;

.include"m2560def.inc"
.def i=r16
.def n_byte0=r5
.def n_byte1=r6
.def n_byte2=r7
.def n_byte3=r8

.dseg

result:.byte 4

.cseg

rjmp bp
s:.db "325658"
bp:

clr n_byte0
clr n_byte1
clr n_byte2
clr n_byte3
clr i
clr r2
ldi r21, 10
clr r17
clr r18
clr r19
clr r20

ldi zl, low(s<<1)
ldi zh, high(s<<1)
ldi yl, low(result)
ldi yh, high(result)

for: cpi i, 6
brsh end

mul n_byte0, r21
movw r23:r22, r1:r0
clr r24
clr r25
add r17, r22
adc r18, r23
adc r19, r24
adc r20, r25

mul n_byte1, r21
mov r24, r1
mov r23, r0
clr r22
clr r25
add r17, r22
adc r18, r23
adc r19, r24
adc r20, r25

mul n_byte2, r21
movw r25:r24, r1:r0
clr r22
clr r23
add r17, r22
adc r18, r23
adc r19, r24
adc r20, r25

lpm r0,z+
ldi r27, 0x30
sub r0, r27
add r17, r0
adc r18, r2
adc r19, r2
adc r20, r2

inc i

mov n_byte3, r20
mov n_byte2, r19
mov n_byte1, r18
mov n_byte0, r17
clr r17
clr r18
clr r19
clr r20
rjmp for

end:st y+, n_byte0
st y+, n_byte1
st y+, n_byte2
st y, n_byte3
rjmp loopforever

loopforever:rjmp loopforever
