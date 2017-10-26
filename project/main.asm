/*
 * main.asm
 *
 *  Created: 20/10/2017 10:11:17 AM
 *   Author: Liangde Li z5077896 Dankoon Yoo z5116090
 */ 

 /*
 Display "Max stations:"
 Get input NUM
 for(i=1; i<=NUM; i++){
     display "Namei: "
	 Get input NAMEi
 }
 for(i=1; i<=NUM; i++){
     Time i to i+1: 
	 Get input TIMEi
 }
 Display "Stop time: "
 Get input STOPTIME
 Display "Done, wait"
 DC running 60
 if PB0, light up LED0-3
 if PB1, light up LED4-7
 if #, stop, then #, start again
 LCD display next stop
 when stop, 2 LEDs blink
 */
 
.include "m2560def.inc"

.def temp = r16
.def temp1 = r17
.def row =r18
.def col =r19
.def mask =r20
.def d_5 = r15
.def d_4 = r14
.def d_3 = r13
.def d_2 = r12
.def d_1 = r11
.def result_high = r7
.def result_low = r6
.equ PORTLDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

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
	SecondCounter: .byte 2 ; Two-byte counter for counting seconds.
	TempCounter: .byte 2 ; Temporary counter. Used to determine if one second has passed
	RevCounter: .byte 2 ; revolution counter, for counting revolution in 1/10 seconds
	TargetSpeed: .byte 1 

.cseg
	.org 0x0000
		jmp RESET
/*	.org INT0addr ; INT0addr is the address of EXT_INT0
		jmp EXT_INT0
	.org INT1addr ; INT1addr is the address of EXT_INT1
		jmp EXT_INT1
	.org INT2addr ; 
		jmp EXT_INT2*/
	.org OVF0addr
		jmp Timer0OVF ; Jump to the interrupt handler for
						; Timer0 overflow.
	jmp DEFAULT          ; default service for all other interrupts.
	DEFAULT:  reti       ; no service

//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// RESET module
// start here
RESET:
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	ser r16
	out DDRE, r16
	// LCD
	out DDRF, r16
	out DDRA, r16
	clr temp
	out PORTF, r16
	out PORTA, r16
	clr temp
	out DDRD, temp
	out PORTD, temp
	// Interrupts
	ldi temp, (2 << ISC20) | (2 << ISC10) | (2 << ISC00)
	sts EICRA, temp
	in temp, EIMSK
	ori temp, (1<<INT2) | (1<<INT0) | (1<<INT1)
	out EIMSK, temp
	// keypad
	ldi temp, PORTLDIR ; columns are outputs, rows are inputs
    STS DDRL, temp     ; cannot use out
    // LEDs
	ser temp
    out DDRC, temp ; Make PORTC all outputs
    out PORTC, temp ; Turn on all the LEDs

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

	do_lcd_data 'M'
	do_lcd_data 'a'
	do_lcd_data 'x'
	do_lcd_data ' '
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data 's'
	do_lcd_data ':'

	sei
	jmp main
// end here
// RESET module



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// Interrupt 0 module
// start here
/*EXT_INT0:
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
	reti*/
// end here
// Interrupt 0 module



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// Interrupt 1 module
// start here
/*EXT_INT1:
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
	reti*/
// end here
// Interrupt 1 module



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// Interrupt 2 module
// start here
/*EXT_INT2:
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
		reti*/
// end here
// Interrupt 2 module



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// Timer0 module
// start here
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
// end here
// Timer0 module    



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// main function
// start here
main: ; main - does nothing 
	//clr flag
	//clear_2 RevCounter
	clear_2 TempCounter ; initialize the temporary counter to 0
    clear_2 SecondCounter ; initialize the second counter to 0
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000010
	out TCCR0B, temp ; set prescalar value to 8
	ldi temp, 1<<TOIE0 ; TOIE0 is the bit number of TOIE0 which is 0
	sts TIMSK0, temp ; enable Timer0 Overflow Interrupt
	sei ; enable global interrupt
	call GetKeypadNumInput
	ldi temp1, 48
	add temp, temp1
	display
	loop: rjmp loop
// end here
// main function



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// GetKeypadNumInput module, temp=0
// start here
// 0-9, A=0xA, B=0xB, C=0xC, D=0xD, *=0xE, #=0xF
; keeps scanning the keypad to find which key is pressed.
GetKeypadNumInput:
	ldi mask, INITCOLMASK ; initial column mask
	clr col ; initial column
	colloop:
		STS PORTL, mask ; set column to mask value
		; (sets column 0 off)
		ldi temp, 0xFF ; implement a delay so the
		; hardware can stabilize
		delay:
			dec temp
			brne delay
		LDS temp, PINL ; read PORTL. Cannot use in 
		andi temp, ROWMASK ; read only the row bits
		cpi temp, 0xF ; check if any rows are grounded
		breq nextcol ; if not go to the next column
		ldi mask, INITROWMASK ; initialise row check
		clr row ; initial row
		rowloop:      
			mov temp1, temp
			and temp1, mask ; check masked bit
			brne skipconv ; if the result is non-zero,
			; we need to look again
			rjmp convert ; if bit is clear, convert the bitcode
			skipconv:
			inc row ; else move to the next row
			lsl mask ; shift the mask to the next bit
			rjmp rowloop          
		nextcol:     
			cpi col, 3 ; check if we^Òre on the last column
			breq GetKeypadNumInput ; if so, no buttons were pushed,
			; so start again.

			sec ; else shift the column mask:
			; We must set the carry bit
			rol mask ; and then rotate left by a bit,
			; shifting the carry into
			; bit zero. We need this to make
			; sure all the rows have
			; pull-up resistors
			inc col ; increment column value
			jmp colloop ; and check the next column
	; convert function converts the row and column given to a
	; binary number and also outputs the value to PORTC.
	; Inputs come from registers row and col and output is in
	; temp.
	convert:
		cpi col, 3 ; if column is 3 we have a letter
		breq letters
		cpi row, 3 ; if row is 3 we have a symbol or 0
		breq symbols
		mov temp, row ; otherwise we have a number (1-9)
		lsl temp ; temp = row * 2
		add temp, row ; temp = row * 3
		add temp, col ; add the column address
		; to get the offset from 1
		inc temp ; add 1. Value of switch is
		; row*3 + col + 1.
		jmp convert_end
		letters:
		ldi temp, 0xA
		add temp, row ; increment from 0xA by the row value
		jmp convert_end
		symbols:
		cpi col, 0 ; check if we have a star
		breq star
		cpi col, 1 ; or if we have zero
		breq zero
		ldi temp, 0xF ; we'll output 0xF for hash
		jmp convert_end
		star:
		ldi temp, 0xE ; we'll output 0xE for star
		jmp convert_end
		zero:
		clr temp ; set to zero
		convert_end:
		//out PORTC, temp ; write value to PORTC
		
		ret ; return to caller
// end here
// GetKeypadNumInput



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



// LCD setting and displaying module
// start here
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
// end here
// LCD setting and displaying module



//*************************************************************************************************************
// boarder for modules
//*************************************************************************************************************



//Currently not using modules:

calculation:
	/*do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?*/
	/*do_lcd_command 0b00000001 ; clear display
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
	do_lcd_data '0'*/
	jmp end_calculation
