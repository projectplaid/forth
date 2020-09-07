@ Plaid FORTH
@ based on Richard Jones' jonesforth

	.set INITIAL_DATA_SEGMENT_SIZE, 65536
	.set RETURN_STACK_SIZE, 8192
	.set BUFFER_SIZE, 4096

DSP	.req	r13
RSP	.req	r11
FIP	.req	r10

	.text
	.global forth
forth:
	wfe
	
	.macro PUSHRSP reg
	str		\reg, [RSP, #-4]!
	.endm

	.macro POPRSP reg
	ldr		\reg, [RSP], #4
	.endm

	.macro PUSHDSP reg
	push 	{\reg}
	.endm
	
	.macro POPDSP reg
	pop 	{\reg}
	.endm

	.macro PUSHR regs:vararg
	stmfd	RSP!, \regs
	.endm

	.macro POPR regs:vararg
	ldmfd	RSP!, \regs
	.endm

	.macro PUSHD regs:vararg
	push	\regs
	.endm

	.macro POPD regs:vararg
	pop		\regs
	.endm

	.macro NEXT
	ldr		r0, [FIP], #4			@ load word at FIP, increment it
	ldr		r1, [r0]				@ load CODEWORD
	bx		r1						@ branch to CODEWORD
	.endm

	.text
	.align 2
DOCOL:
	PUSHRSP	FIP						@ put FIP on the return stack
	add		FIP, r0, #4				@ skip codeword, FIP is the first dataword
	NEXT

	.pool

	.section .rodata
cold_start:
	.int	QUIT

	.bss
	.align 12
return_stack:
	.space 	RETURN_STACK_SIZE
return_stack_top:

	.align 12
buffer:
	.space	BUFFER_SIZE

	.set	F_IMM, 0x80
	.set	F_HID, 0x20
	.set	F_LEN, 0x1f

	.set	link, 0

	.macro	defword name, flags=0, label
	.section .rodata
	.align	2
	.global	name_\label
name_\label :
	.int	link
	.set	link, name_\label
	.byte	\flags+(str_end_\label-str_\label)
str_\label :
	.ascii	"\name"
str_end_\label :
	.align 	2
	.global \label
\label :
	.int	DOCOL
	@ forth word pointers go here
	.endm

	.macro	defcode name, flags=0, label
	.section .rodata
	.align	2
	.global	name_\label
name_\label :
	.int	link
	.set	link, name_\label
	.byte	\flags+(str_end_\label-str_\label)
str_\label :
	.ascii	"\name"
str_end_\label :
	.align	2
	.global \label
\label :
	.int	code_\label
	.text
	.global	code_\label
code_\label :
	@ assembler code goes here
	.endm

	.macro defvar name, flags=0, label, initial=0
	defcode \name, \flags, \label
	ldr		r0, =var_\name			@ load address
	PUSHDSP	r0						@ push address
	NEXT
	.data
	.align 	2
	.global var_\name
var_\name :
	.int	\initial
	.endm

	.macro defconst name, flags=0, label, value
	defcode \name, \flags, \label
	ldr		r0, =\value
	PUSHDSP	r0
	NEXT
	.endm

defconst "VERSION",,VERSION,1
defconst "R0",,R0,return_stack_top
defconst "F_IMMED",,F_IMMED,F_IMM
defconst "F_HIDDEN",,F_HIDDEN,F_HID
defconst "F_LENMASK",,F_LENMASK,F_LEN

defvar "STATE",,STATE
defvar "HERE",,HERE
defvar "LATEST",,LATEST,name_EXECUTE
defvar "S0",,S0
defvar "BASE",,BASE,10

defcode "FALSE",,FALSE
	mov		r0, #0
	PUSHDSP r0
	NEXT

defcode "TRUE",,TRUE
	mvn		r0, #0
	PUSHDSP r0
	NEXT 

defcode "EXIT",,EXIT
	POPRSP	FIP
	NEXT

// FORTH 2012 Standard 

// CORE words

// DROP ( a -- )
// Remove a from the stack. 
defcode "DROP",,DROP
	add		DSP, DSP, #4
	NEXT

// DUP ( a -- a a )
// Duplicate a. 
defcode "DUP",,DUP
	ldr		r0, [DSP]
	PUSHDSP r0
	NEXT

// SWAP ( a b -- b a )
// Exchange the top two stack items. 
defcode "SWAP",,SWAP
	POPDSP	r1
	POPDSP	r0
	PUSHDSP	r0
	PUSHDSP r1
	NEXT

// OVER ( a b -- a b a )
// Place a copy of a on top of the stack
defcode "OVER",,OVER
	ldr		r0, [DSP, #4]
	PUSHDSP	r0
	NEXT

// ROT ( a b c -- c a b )
// Rotate the top three stack entries. 
defcode "ROT",,ROT
	POPDSP	r1
	POPDSP	r2
	POPDSP	r0
	PUSHDSP	r2
	PUSHDSP r1
	PUSHDSP r0
	NEXT

// 2DROP ( a b -- )
// Drop cell pair a b from the stack. 
defcode "2DROP",,TWODROP
	add		DSP, DSP, #8
	NEXT

// 2DUP ( a b -- a b a b )
// Duplicate cell pair a b.
defcode "2DUP",,TWODUP
	ldmia	DSP, {r0,r1}
	PUSHDSP	r1
	PUSHDSP	r0
	NEXT

// 2OVER ( a b c d -- a b c d a b ) 
// Copy cell pair a b to the top of the stack. 
defcode "2OVER",,TWOOVER
	ldr		r0, [DSP, #8]
	ldr		r1, [DSP, #12]
	PUSHDSP	r1
	PUSHDSP r0
	NEXT

// 2SWAP ( a b c d -- c d a b ) 
// Exchange the top two cell pairs.
defcode "2SWAP",,TWOSWAP
	POPDSP	r3
	POPDSP	r2
	POPDSP	r1
	POPDSP	r0
	PUSHDSP	r1
	PUSHDSP r0
	PUSHDSP r3
	PUSHDSP r2
	NEXT

// NIP ( a b -- b )
// Drop the first item below the top of stack. 
defcode "NIP",,NIP
	POPDSP	r1
	POPDSP	r0
	PUSHDSP	r0
	NEXT

// TUCK ( a b -- b a b )
// Copy the first (top) stack item below the second stack item. 
defcode "TUCK",,TUCK
	POPDSP 	r1
	POPDSP	r0
	PUSHDSP r0
	PUSHDSP r1
	PUSHDSP r0
	NEXT

// PICK ( xu...x1 x0 u -- xu...x1 x0 xu ) 
// Remove u. Copy the xu to the top of the stack. An ambiguous condition exists 
// if there are less than u+2 items on the stack before PICK is executed. 
defcode "PICK",,PICK
	POPDSP	r0						@ r0 = u
	ldr		r1, [DSP, r0, LSL #2]	@ r1 = xu
	PUSHDSP	r1
	NEXT

// ?DUP ( x -- 0 | x x )
// Duplicate x if it is non-zero. 
defcode "?DUP",,QDUP
	ldr		r0, [DSP]				@ r0 = x
	cmp		r0, #0
	strne 	r0, [DSP, #-4]!			@ if r0 != 0, push
	NEXT

// 1+ ( x -- x+1 )
// Add one (1) to x giving the result x+1. 
defcode "1+",,INCR
	POPDSP	r0
	add		r0, r0, #1
	PUSHDSP	r0
	NEXT

// 1- ( x -- x-1 )
// Subtract one (1) from x giving the result x-1.
defcode "1-",,DECR
	POPDSP	r0
	sub 	r0, r0, #1
	PUSHDSP	r0
	NEXT

// + ( x y -- x+y )
// Add y to x, giving the sum y+x.
defcode "+",,ADD
	POPDSP	r1
	POPDSP	r0
	add 	r0, r0, r1
	PUSHDSP	r0
	NEXT

// - ( x y -- x-y )
// Subtract y from x, giving the difference y-x.
defcode "-",,SUB
	POPDSP	r1
	POPDSP	r0
	sub		r0, r1, r0
	PUSHDSP	r0
	NEXT

// * ( x y -- x*y )
// Multiply x  by y giving the product x*y.
defcode "*",,MUL
	POPDSP	r1
	POPDSP	r0
	mul 	r2, r1, r0
	PUSHDSP	r2
	NEXT

_DIVMOD:
	mov		r3, r1

	cmp		r3, r0, LSR #1
1:	movls	r3, r3, LSL #1
	cmp		r3, r0, LSR #1
	bls		1b

	mov 	r2, #0
2:	cmp 	r0, r3
	subcs	r0, r0, r3
	adc 	r2, r2, r3
	mov 	r3, r3, LSR #1
	cmp		r3, r1
	bhs		2b

	bx		lr

// / ( x y -- x/y )
// Divide x by y, giving the single-cell quotient x/y. An ambiguous condition 
// exists if y is zero. If x and y differ in sign, the implementation-defined 
// result returned will be the same as that returned by either the phrase 
// >R S>D R> FM/MOD SWAP DROP or the phrase >R S>D R> SM/REM SWAP DROP.
defcode "/",,DIV
	POPDSP	r1
	POPDSP	r0
	bl		_DIVMOD
	PUSHDSP	r2
	NEXT

// MOD ( x y -- x/y )
// Divide x by y, giving the single-cell remainder x/y. An ambiguous condition 
// exists if y is zero. If x and y differ in sign, the implementation-defined 
// result returned will be the same as that returned by either the phrase 
// >R S>D R> FM/MOD DROP or the phrase >R S>D R> SM/REM DROP.  
defcode	"MOD",,MOD
	POPDSP	r1
	POPDSP	r0
	bl		_DIVMOD
	PUSHDSP	r0
	NEXT

// 2* ( x -- x*2 )
// x*2 is the result of shifting x one bit toward the most-significant bit, 
// filling the vacated least-significant bit with zero. 
defcode "2*",,MUL2
	POPDSP	r0
	mov		r0, r0, LSL #1
	PUSHDSP	r0
	NEXT

// 2/ ( x -- x/2 )
// x/2 is the result of shifting x one bit toward the least-significant bit, 
// leaving the most-significant bit unchanged. 
defcode "2/",,DIV2
	POPDSP	r0
	mov		r0, r0, ASR #1
	PUSHDSP	r0
	NEXT

// LSHIFT ( x u -- x<<u )
// Perform a logical left shift of u bit-places on x, giving x<<u. Put zeroes into 
// the least significant bits vacated by the shift. An ambiguous condition exists 
// if u is greater than or equal to the number of bits in a cell.  
defcode "LSHIFT",,LSHIFT
	POPDSP	r0
	POPDSP	r1
	mov 	r0, r1, LSL r0
	PUSHDSP	r0
	NEXT

// RSHIFT ( x u -- x>>u )
// Perform a logical right shift of u bit-places on x, giving x>>u. Put zeroes into 
// the most significant bits vacated by the shift. An ambiguous condition exists if 
// u is greater than or equal to the number of bits in a cell.  
defcode "RSHIFT",,RSHIFT
	POPDSP	r0
	POPDSP	r1
	mov		r0, r1, LSR r0
	PUSHDSP	r0
	NEXT

// QUIT ( -- ) first word executed
defword "QUIT",,QUIT
	.int	R0, RSPSTORE
	.int	S0, FETCH, DSPSTORE
	.int	INTERPRET
	.int	BRANCH, -8

// EXECUTE ( xt -- ) jump to the address on the stack
// THIS MUST BE THE LAST WORD DEFINED
defcode "EXECUTE",,EXECUTE
	POPDSP	r0
	ldr		r1, [r0]
	bx		r1