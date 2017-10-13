/*
 * TaskC.asm
 *
 *  Created: 13/10/2017 1:22:37 PM
 *   Author: Liangde Li z5077896 Dankoon Yoo z5116090
 */ 

 .include "m2560def.inc"
.def temp =r16
.def row =r17
.def col =r18
.def mask =r19
.def temp2 =r20
.def flag = r21 ; 0:None, 1:+, 2:-
.def expression_high = r24
.def expression_low = r23
.def result_high = r15
.def result_low = r14
.def d_5 = r12
.def d_4 = r11
.def d_3 = r10
.def d_2 = r9
.def d_1 = r22
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
.macro display
	rcall lcd_data
	rcall lcd_wait
.endmacro

.cseg
jmp RESET

.org 0x72
RESET:
ldi flag, 0
clr expression_high
clr expression_low
clr result_high
clr result_low
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, PORTLDIR ; columns are outputs, rows are inputs
STS DDRL, temp     ; cannot use out
ser r16
out DDRF, r16
out DDRA, r16
clr r16
out PORTF, r16
out PORTA, r16
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
/*ser temp
out DDRC, temp ; Make PORTC all outputs
out PORTC, temp ; Turn on all the LEDs*/
; main keeps scanning the keypad to find which key is pressed.
main:
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
mov temp2, temp
and temp2, mask ; check masked bit
brne skipconv ; if the result is non-zero,
; we need to look again
rcall convert ; if bit is clear, convert the bitcode
jmp main ; and start again
skipconv:
inc row ; else move to the next row
lsl mask ; shift the mask to the next bit
jmp rowloop          
nextcol:     
cpi col, 3 ; check if we^Òre on the last column
breq main ; if so, no buttons were pushed,
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
breq is_symbols
rjmp not_symbols
is_symbols:
jmp symbols
not_symbols:
mov temp, row ; otherwise we have a number (1-9)
lsl temp ; temp = row * 2
add temp, row ; temp = row * 3
add temp, col ; add the column address
; to get the offset from 1
inc temp ; add 1. Value of switch is
; row*3 + col + 1.
ldi r22, 10
mul expression_high, r22
mov expression_high, r0
mul expression_low, r22
mov expression_low, r0
add expression_high, r1
ldi r22, 0
add expression_low, r16
adc expression_high, r22
ldi r22, 48
add r16, r22
display
jmp convert_end
letters:
cpi row, 0
breq A
cpi row, 1
breq B
cpi row, 2
breq is_C
jmp convert_end
is_C:
jmp C
A:
do_lcd_data '-'
cpi flag, 1
breq plus_2
cpi flag, 2
breq minus_2
mov result_low, expression_low
mov result_high, expression_high
clr expression_low
clr expression_high
rjmp set_flag_minus
minus_2:
sub result_low, expression_low
sbc result_high, expression_high
clr expression_low
clr expression_high
rjmp set_flag_minus
plus_2:
add result_low, expression_low
adc result_high, expression_high
clr expression_low
clr expression_high
set_flag_minus:
/*						mov r16, result_high
						ldi temp2, 48
						add r16, temp2
						display
						mov r16, result_low
						ldi temp2, 48
						add r16, temp2
						display*/
ldi flag, 2
jmp convert_end
B:
do_lcd_data '+'
cpi flag, 1
breq plus_1
cpi flag, 2
breq minus_1
mov result_low, expression_low
mov result_high, expression_high
clr expression_low
clr expression_high
rjmp set_flag_plus
minus_1:
sub result_low, expression_low
sbc result_high, expression_high
clr expression_low
clr expression_high
rjmp set_flag_plus
plus_1:
add result_low, expression_low
adc result_high, expression_high
clr expression_low
clr expression_high
set_flag_plus:
/*					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display*/
ldi flag, 1
jmp convert_end
C:
do_lcd_data '='
cpi flag, 1
breq plus_3
cpi flag, 2
breq minus_3
;rjmp end_of_equal
minus_3:
sub result_low, expression_low
sbc result_high, expression_high
clr expression_low
clr expression_high
rjmp end_of_equal
plus_3:
add result_low, expression_low
adc result_high, expression_high
clr expression_low
clr expression_high
end_of_equal:
/*						mov r16, result_high
						ldi temp2, 48
						add r16, temp2
						display
						mov r16, result_low
						ldi temp2, 48
						add r16, temp2
						display*/
jmp calculation
end_calculation:
jmp convert_end
symbols:
cpi col, 0 ; check if we have a star
breq star
cpi col, 1 ; or if we have zero
breq zero
;'#'
jmp convert_end
star:
;'*'
jmp convert_end
zero:
ldi temp, 48 
display
ldi r22, 10
mul expression_high, r22
mov expression_high, r0
mul expression_low, r22
mov expression_low, r0
add expression_high, r1
/*ldi r22, 0
add expression_low, r16
adc expression_high, r22*/

convert_end:

/*do_lcd_data ' '
mov r16, expression_high
ldi temp2, 48
add r16, temp2
display
mov r16, expression_low ;..............................................................................
ldi temp2, 48
add r16, temp2
display
do_lcd_data ' '*/

ldi r22, 1
clr r13
ldi r27, 0xC0
ldi r28, 0x27
ldi r29, 0x09
delay_in:
sub r27, r22
sbc r28, r13
sbc r29, r13
cp r27, r13
cpc r28, r13
cpc r29, r13 
brne delay_in
ret ; return to caller


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


/*plus:
add result_low, expression_low
adc result_high, expression_high
clr expression_low
clr expression_high
ret*/

/*minus:
sub result_low, expression_low
sbc result_high, expression_high
clr expression_low
clr expression_high
mov r16, result_high
ldi temp2, 48
add r16, temp2
display
mov r16, result_low
ldi temp2, 48
add r16, temp2
display
ret*/

calculation:
ldi r25, low(10000)
mov r3, r25
ldi r25, high(10000)
mov r4, r25
ldi r25, low(1000)
mov r5, r25
ldi r25, high(1000)
mov r6, r25
ldi r25, 100
mov r7, r25
ldi r25, 10
mov r8, r25
clr d_5
clr d_4
clr d_3
clr d_2
clr d_1
ldi r25, 0b10000000
and r25, result_high
cpi r25, 0
breq is_positive
rjmp is_negative
is_positive:
jmp positive
is_negative:
ldi r25, 0

add_ten_thousand:
add result_low, r3
adc result_high, r4
inc d_5
cp result_low, r25
cpc result_high, r25
brlt add_ten_thousand
sub result_low, r3
sbc result_high, r4
dec d_5

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

add_thousand:
add result_low, r5
adc result_high, r6
inc d_4
cp result_low, r25
cpc result_high, r25
brlt add_thousand
sub result_low, r5
sbc result_high, r6
dec d_4

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

add_hundred:
add result_low, r7
adc result_high, r25
inc d_3
cp result_low, r25
cpc result_high, r25
brlt add_hundred
sub result_low, r7
sbc result_high, r25
dec d_3

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

add_ten:
add result_low, r8
adc result_high, r25
inc d_2
cp result_low, r25
cpc result_high, r25
brlt add_ten
sub result_low, r8
sbc result_high, r25
dec d_2

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

mov d_1, result_low

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

loop2:
    rjmp loop2

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
do_lcd_data '-'
mov r16, d_5
ldi r27, 48
add r16, r27
display
mov r16, d_4
add r16, r27
display
mov r16, d_3
add r16, r27
display
mov r16, d_2
add r16, r27
display
mov r16, d_1
add r16, r27
display
jmp end_calculation

positive:
ldi r25, 0

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

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

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

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

sub_hundred:
sub result_low, r7
adc result_high, r25
inc d_3
cp result_low, r25
cpc result_high, r25
brge sub_hundred
add result_low, r7
adc result_high, r25
dec d_3

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

sub_ten:
sub result_low, r8
sbc result_high, r25
inc d_2
cp result_low, r25
cpc result_high, r25
brge sub_ten
add result_low, r8
adc result_high, r25
dec d_2

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

mov d_1, result_low

					mov r16, result_high
					ldi temp2, 48
					add r16, temp2
					display
					mov r16, result_low
					ldi temp2, 48
					add r16, temp2
					display

loop1:
    rjmp loop1

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
do_lcd_data '+'
mov r16, d_5
ldi r27, 48
add r16, r27
display
mov r16, d_4
add r16, r27
display
mov r16, d_3
add r16, r27
display
mov r16, d_2
add r16, r27
display
mov r16, d_1
add r16, r27
display
jmp end_calculation