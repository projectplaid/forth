    .extern forth
	.extern uart_init
	.section ".text.boot"
	.global _start
_start:
	@ read CPU ID, stop the secondary cores
	mrc		p15, 0, r5, c0, c0, 5
	and		r5, r5, #3
	cmp		r5, #0
	bne		halt
	
	@ set up the stack
	ldr		r5, =_start
	mov		sp, r5
	
	@ clear BSS
	ldr		r4, =__bss_start
	ldr		r9, =__bss_end
	mov		r5, #0
	mov		r6, #0
	mov		r7, #0
	mov		r8, #0
	b		2f
1:	@ store in multiples of 4
	stmia	r4!, {r5-r8}
2:	@ if we're still below __bss_end, loop
	cmp		r4, r9
	blo		1b

	@ setup the UART
	bl		uart_init
	
	@ start FORTH
	bl		forth

halt:
	wfe
