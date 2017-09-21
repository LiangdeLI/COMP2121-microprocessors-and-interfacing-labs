;
; TaskA.asm
;
; Created: 25/08/2017 3:12:42 PM
; Author : Liangde LI z5077896 | Dankoon Yoo z5116090
;


; Replace with your application code
.include "m2560def.inc"

.def Dividend_High=r16
.def Dividend_Low=r15
.def Divisor_High=r18
.def Divisor_Low=r17
.def Quotient_High=r20 
.def Quotient_Low=r19
.def Bit_position_High=r22
.def Bit_position_Low=r21

.cseg
.org 0x00

ldi Dividend_High, high(50000)      ;Dividend=3217
ldi r24, low(5000)
mov Dividend_Low, r24
ldi Divisor_High, high(50)        ;Divisor=16
ldi Divisor_Low, low(50)
clr Quotient_High
clr Quotient_Low
ldi Bit_position_High, high(0x01)   ;Bit position = 1
ldi Bit_position_Low, low(0x01) 

while1:
cp Dividend_Low, Divisor_Low        ;branch if dividend==divisor
cpc Dividend_High, Divisor_High
breq while2
cp Dividend_Low, Divisor_Low        ;branch if dividend<divisor
cpc Dividend_High, Divisor_High
brlo while2
ldi r23, 0x80                       ;branch if (divisor & 0x8000) is negative in signed version
and r23, Divisor_High
cpi r23, 0x00
brlt while2 
lsl Divisor_Low                     ;divisor left shift 1 bit
rol Divisor_High
lsl Bit_position_Low                ;bit position left shift 1 bit
rol Bit_position_High
rjmp while1

while2:
clr r0
cp Bit_position_Low, r0             ;end if bit position == 0
cpc Bit_position_High, r0
breq loopforever
cp Dividend_Low, Divisor_Low        ;branch if dividend < divisor
cpc Dividend_High, Divisor_High
brlo then
sub Dividend_Low, Divisor_Low       ;dividend-=divisor
sbc Dividend_High, Divisor_High
add Quotient_Low, Bit_position_Low  ;quotient+=bit_position
adc Quotient_High, Bit_position_High 
then:
asr Divisor_High                    ;divisor right shift one bit
ror Divisor_Low
asr Bit_position_High               ;bit_position right shift one bit
ror Bit_position_Low
rjmp while2

loopforever:rjmp loopforever
