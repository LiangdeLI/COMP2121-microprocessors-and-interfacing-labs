/*
 * lab01_4.asm
 *
 *  Created: 18/08/2017 11:07:15 AM
 *  Author: Liangde Li z5077896, Dankoon Yoo z5116090
 */ 

 .include "m2560def.inc"
 .def i=r16
 .def j=r17
 .def k=r18
 .def Aik=r19
 .def Bkj=r20
 .def Cij_low=r9
 .def Cij_high=r10
 .equ n=5
 .equ nn=25

 .dseg
 .org 0x200
 A_start:.byte 25
 B_start:.byte 25
 C_start:.byte 50

 .cseg
 .org 0x00

 ;initialize A, B, C
 ldi zl, low(A_start)
 ldi zh, high(A_start)
 ldi yl, low(B_start)
 ldi yh, high(B_start)
 ldi xl, low(C_start)
 ldi xh, high(C_start)

 clr i
 clr j
 forI:cpi i, n
 brge forI_end
 clr j
 forJ:cpi j, n
 brge forJ_end
 
 clr r0
 add r0, i
 add r0, j
 st z+, r0

 clr r0
 add r0, i
 sub r0, j
 st y+, r0

 clr r0
 clr r1
 st x+, r0
 st x+, r1

 inc j
 rjmp forJ
 
 forJ_end: inc i
 rjmp forI
 
 forI_end:ldi zl, low(A_start)
 ldi zh, high(A_start)
 ldi yl, low(B_start)
 ldi yh, high(B_start)
 ldi xl, low(C_start)
 ldi xh, high(C_start)

 clr i
 clr j
 clr k

 for1:cpi i, n
 brge loopforever
 clr j
 for2:cpi j, n
 brge for2_end
 clr Cij_low
 clr Cij_high
 clr k
 for3:cpi k, n
 brge for3_end
 
 ld Aik, z+
 ld Bkj, y
 ldi r24, 5
 clr r25
 add yl, r24
 adc yh, r25
 
 muls Aik, Bkj
 add Cij_low, r0
 adc Cij_high, r1

 inc k
 rjmp for3
 for3_end:
 st x+, Cij_low
 st x+, Cij_high
 ldi r24, 5
 clr r25
 sub zl, r24
 sbc zh, r25
 ldi r24, 24
 clr r25
 sub yl, r24
 sbc yh, r25
 inc j
 rjmp for2
 for2_end:inc i
 ldi r24, 5
 clr r25
 add zl, r24
 adc zh, r25
 ldi r24, 5
 clr r25
 sub yl, r24
 sbc yh, r25
 rjmp for1
 loopforever:rjmp loopforever
