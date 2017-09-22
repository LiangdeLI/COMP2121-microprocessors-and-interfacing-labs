/*
 * TaskC.asm
 *
 *  Created: 22/09/2017 1:25:24 PM
 *   Author: Liangde Li z5077896 Dankoon Yoo z5116090
 */ 

  .include "m2560def.inc"
  .def temp = r16
  .def mins = r17
  .def secd = r18
  .def mask = r19
  .equ START_TIME = 0b00000000 ; 0b11011111
  .equ PATTERN = 0xFF
  .cseg
  .org 0x0

  
  ldi temp, PATTERN
  out DDRC, temp
  ldi r16, START_TIME
  out PORTC, temp
  ldi secd, 0
  ldi mins, 0
  
  loop:
  clr temp
  
  ldi mask, 0b00100000
  and mask, secd
  lsr mask ; shift right 3
  lsr mask
  lsr mask
  or temp, mask

  ldi mask, 0b00010000
  and mask, secd
  lsr mask
  or temp, mask

  ldi mask, 0b00001000
  and mask, secd
  lsl mask
  or temp, mask

  ldi mask, 0b00000100
  and mask, secd
  lsl mask
  lsl mask
  lsl mask
  or temp, mask

  ldi mask, 0b00000010
  and mask, secd
  lsl mask
  lsl mask
  lsl mask
  lsl mask
  lsl mask
  or temp, mask

  ldi mask, 0b00000001
  and mask, secd
  lsl mask
  lsl mask
  lsl mask
  lsl mask
  lsl mask
  lsl mask
  lsl mask
  or temp, mask

  ldi mask, 0b00000001
  and mask, mins
  lsl mask
  or temp, mask

  ldi mask, 0b00000010
  and mask, mins
  lsr mask
  or temp, mask

  out PORTC, temp

  ldi r20, 0x92 ;16000000/7   
  ldi r21, 0xE0
  ldi r22, 0x22
  ldi r23, 1
  ldi r24, 0
  delay:
  sub r20, r23
  sbc r21, r24
  sbc r22, r24
  cp r20, r23
  cpc r21, r24
  cpc r22, r24
  brne delay

  inc secd
  cpi secd, 60
  brne continue
  ldi secd, 0
  inc mins
  continue:
  rjmp loop