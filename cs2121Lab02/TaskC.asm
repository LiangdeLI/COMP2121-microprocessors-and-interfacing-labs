/*
 * TaskC.asm
 *
 *  Created: 1/09/2017 3:37:52 PM
 *   Author: Liangde Li z5077896
 */ 

 .include "m2560def.inc"

 .dseg 
 .org 0x200
 counter:.byte 1

 .cseg
 .org 0x00


 ldi yl, low(RAMEND)
 ldi yh, high(RAMEND)
 ;sbiw yh:yl, 4
 out SPH, r29
 out SPH, r28
 ;ldi r25, counter
 ldi zl, low(counter) 
 ldi zh, high(counter)
 ldi r25, 0
 st z, r25
 ldi r16, 8 ;n=8
 ldi r17, 1 ;A=1
 ldi r18, 3 ;B=3
 ldi r19, 2 ;C=2

 rcall move

 loopforever: rjmp loopforever

 move:
 ;prologue
 push yl
 push yh
 in yl, SPL
 in yh, SPH
 sbiw yh:yl, 4
 out SPH, yh
 out SPH, yl
 std y+4, r16 ; y+4 store n
 std y+3, r17 ; y+3 store A
 std y+2, r18 ; y+2 store C
 std y+1, r19 ; y+1 store B
 
 cpi r16, 1     ;if(n==1)
 breq one_case

 ldd r16, y+4     ;move(n-1, A, B, C)
 ldi r21, 1
 sub r16, r21
 ldd r17, y+3 ;A
 ldd r18, y+1 ;B
 ldd r19, y+2 ;C
 rcall move

 ldi r16, 1       ;move(1, A, C, B)
 ldd r17, y+3 ;A
 ldd r18, y+2 ;C
 ldd r19, y+1 ;B
 rcall move

 ldd r16, y+4     ;move(n-1, B, C, A)
 ldi r21, 1
 sub r16, r21
 ldd r17, Y+1 ;B
 ldd r18, Y+2 ;C
 ldd r19, Y+3 ;A
 rcall move

 rjmp epilogue

 one_case:
 ldi zl, low(counter) 
 ldi zh, high(counter)
 ld r25, z
 inc r25
 st z, r25
 

 epilogue:
 adiw yh:yl, 4
 out SPH, yh
 out SPL, yl
 pop yh
 pop yl
 ret