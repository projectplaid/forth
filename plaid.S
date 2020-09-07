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

	.set	F_IMMED, 0x80
	.set	F_HIDDEN, 0x20
	.set	F_LENMASK, 0x1f

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
	.endm

	.macro defconst name, flags=0, label, value
	defcode \name, \flags, \label
	ldr		r0, =\value
	PUSHDSP	r0
	NEXT
	.endm

defcode "EXIT",,EXIT
	POPRSP	FIP
	NEXT

// QUIT ( -- ) first word executed
defword "QUIT",,QUIT
	.int	R0, RSPSTORE
	.int	S0, FETCH, DSPSTORE
	.int	INTERPRET
	.int	BRANCH, -8
