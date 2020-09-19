    .extern forth
	.extern uart_init
	.extern	uart_putc
	.section ".text.boot"
	.global _start
_start:
    // read cpu id, stop slave cores
    mrs     x1, mpidr_el1
    and     x1, x1, #3
    cbz     x1, 2f
    // cpu id > 0, stop
1:  wfe
    b       1b
2:  // cpu id == 0

    // set stack before our code
    ldr     x1, =_start
    mov     sp, x1

    // clear bss
    ldr     x1, =__bss_start
    ldr     w2, =__bss_size
3:  cbz     w2, 4f
    str     xzr, [x1], #8
    sub     w2, w2, #1
    cbnz    w2, 3b

4:  bl		uart_init
	mov		w0, #0x21
	bl		uart_putc
	mov		w0, #0x68
	bl		uart_putc
	mov		w0, #0x69
	bl		uart_putc
	mov		w0, #0x21
	bl		uart_putc
	// bl      forth
    // for failsafe, halt this core too
    b       1b
