/*
 * TaskB.asm
 *
 *  Created: 20/10/2017 10:11:17 AM
 *   Author: Liangde Li z5077896 Dankoon Yoo z5116090
 */ 

 .include "m2560def.inc"

.def temp = r16
.def temp1 = r17
.def flag = r18
.def holes = r20
.def d_5 = r15
.def d_4 = r14
.def d_3 = r13
.def d_2 = r12
.def d_1 = r11
.def result_high = r7
.def result_low = r6

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

.macro display
	rcall lcd_data
	rcall lcd_wait
.endmacro
                        
.dseg
	SecondCounter: .byte 2  ; Two-byte counter for counting seconds.
	TempCounter: .byte 2    ; Temporary counter. Used to determine 
							; if one second has passed
	RevCounter: .byte 2 ; revolution counter
	TargetSpeed: .byte 1

.cseg
	.org 0x0000
		jmp RESET
	//.org INT0addr ; INT0addr is the address of EXT_INT0
		jmp EXT_INT0
	//.org INT1addr ; INT1addr is the address of EXT_INT1
		jmp EXT_INT1
	//.org INT2addr ; 
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
	
	out DDRE, r16
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

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	do_lcd_data 'S'
	do_lcd_data 'p'
	do_lcd_data 'e'
	do_lcd_data 'e'
	do_lcd_data 'd'
	do_lcd_data ':'
	do_lcd_data '0'
	do_lcd_data '0'
	do_lcd_data '0'
	do_lcd_data '0'
	do_lcd_data '0'

	sei
	jmp main



EXT_INT0:
	push temp
	push temp1
	in temp, SREG
	push temp
	push r21
	push r23
	push r10
	push r9
	push r8
		cpi flag, 1
		brne real_int0
		clr flag
		pop r8
		pop r9
		pop r10
		pop r23
	    pop r21
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
		do_lcd_command 0b00001000 ; display off
		do_lcd_command 0b00000001 ; clear display
	    do_lcd_command 0b00000110 ; increment, no display shift
	    do_lcd_command 0b00001110 ; Cursor on, bar, no blink
		do_lcd_data '0'
		do_lcd_data '0'
		ldi r23, 1
		clr r21
		ldi temp, 0xDB
		mov r8, temp  
		ldi temp, 0x7C
		mov r9, temp
		ldi temp, 0x03
		mov r10, temp
		delay1:
		sub r8, r23
		sbc r9, r21
		sbc r10, r21
		cp r8, r21
		cpc r9, r21
		cpc r10, r21
		brne delay1
	pop r8
	pop r9
	pop r10
	pop r23
	pop r21
	pop temp
	out SREG, temp
	pop temp1
	pop temp
	reti



EXT_INT1:
	push temp
	push temp1
	in temp, SREG
	push temp
	push r21
	push r23
	push r10
	push r9
	push r8
		cpi flag, 1
		brne real_int1
		clr flag
	    pop r8
	    pop r9
	    pop r10
		pop r23
	    pop r21
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
		do_lcd_command 0b00001000 ; display off
		do_lcd_command 0b00000001 ; clear display
	    do_lcd_command 0b00000110 ; increment, no display shift
	    do_lcd_command 0b00001110 ; Cursor on, bar, no blink
		do_lcd_data '1'
		do_lcd_data '1'
		ldi r23, 1
		clr r21
		ldi temp, 0xDB
		mov r8, temp  
		ldi temp, 0x7C
		mov r9, temp
		ldi temp, 0x03
		mov r10, temp
		delay2:
		sub r8, r23
		sbc r9, r21
		sbc r10, r21
		cp r8, r21
		cpc r9, r21
		cpc r10, r21
		brne delay2
	pop r8
	pop r9
	pop r10
	pop r23
	pop r21
	pop temp
	out SREG, temp
	pop temp1
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
	push r24
	push r23
	push r22
	push r21
	push r10 
	push r9
	push r8; prologue ends
		; Load the value of the temporary counter
		lds r24, TempCounter
		lds r25, TempCounter+1
		adiw r25:r24, 1 ; increase the temporary counter by one
		cpi r24, low(781) ; check if (r25:r24) = 7812
		ldi temp, high(781) ; 7812 = 10^6/128
		cpc r25, temp
		brne NotASecond
		rjmp one_tenth_second
	NotASecond:
		jmp NotSecond
	one_tenth_second:
		jmp calculation
	end_calculation:
		lds r22, RevCounter
		lds r23, RevCounter+1
		ldi temp, 10
		; r22*10->r25:r24
		mul r22, temp
		mov r24, r0
		mov r25, r1
		; r23*10->r1:r0
		mul r23, temp
		; r25:r24->r24:r23
		mov r23, r24
		mov r24, r25
		ldi temp, 0
		clr r25
		; 0:r24:r23 + r1:r0:0->r25:r24:r23
		add r23, temp
		adc r24, r0
		adc r25, r1
		lds r21, TargetSpeed
		ldi r22, 0
		cp r23, r21
		cpc r24, r22
		brlo less
		; more
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
 
	EndIF: 
		pop r8 ; epilogue starts
		pop r9 ; restore all conflicting registers from the stack
		pop r10;
		pop r21
		pop r22
		pop r23
		pop r24 
		pop r25 
		pop YL
		pop YH
		pop temp
		out SREG, temp
		reti ; return from the interrupt
    



main: ; main - does nothing 
	clr flag
	clear_2 RevCounter
	clear_2 TempCounter ; initialize the temporary counter to 0
    clear_2 SecondCounter ; initialize the second counter to 0
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



calculation:
	/*do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?*/
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	do_lcd_data 'S'
	do_lcd_data 'p'
	do_lcd_data 'e'
	do_lcd_data 'e'
	do_lcd_data 'd'
	do_lcd_data ':'
	
	
	ldi temp, low(10000)
	mov r3, temp
	ldi temp, high(10000)
	mov r4, temp
	ldi temp, low(1000)
	mov r5, temp
	ldi temp, high(1000)
	mov r6, temp
	ldi temp, 100
	mov r9, temp
	ldi temp, 10
	mov r10, temp
	clr d_5
	clr d_4
	clr d_3
	clr d_2
	clr d_1


	ldi r25, 0
	lds temp, RevCounter
	mov result_low, temp
	lds temp, RevCounter+1
	mov result_high, temp
	clr temp
	/*sts SecondCounter, temp
	sts SecondCounter+1, temp*/
	/*ldi r25, 0b11111111
	mov result_low, r25
	ldi r25, 0b111111
	mov result_high, r25
	ldi r25, 0*/

	sub_ten_thousand:
		sub result_low, r3
		sbc result_high, r4
		inc d_5
		cp result_low, r25
		cpc result_high, r25
		brge sub_ten_thousand
		add result_low, r3
		adc result_high, r4
		dec d_5

	sub_thousand:
		sub result_low, r5
		sbc result_high, r6
		inc d_4
		cp result_low, r25
		cpc result_high, r25
		brge sub_thousand
		add result_low, r5
		adc result_high, r6
		dec d_4

	sub_hundred:
		sub result_low, r9
		sbc result_high, r25
		inc d_3
		cp result_low, r25
		cpc result_high, r25
		brge sub_hundred
		add result_low, r9
		adc result_high, r25
		dec d_3

	sub_ten:
		sub result_low, r10
		sbc result_high, r25
		inc d_2
		cp result_low, r25
		cpc result_high, r25
		brge sub_ten
		add result_low, r10
		adc result_high, r25
		dec d_2

	mov d_1, result_low



	mov r16, d_5
	ldi r27, 48
	add r16, r27
	display
	mov r16, d_4
	add r16, r27
	display
	ldi r27, 48
	mov r16, d_3
	add r16, r27
	display
	ldi r27, 48
	mov r16, d_2
	add r16, r27
	display
	ldi r27, 48
	mov r16, d_1
	add r16, r27
	display
	do_lcd_data '0'
	jmp end_calculation