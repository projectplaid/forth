	.text
	.global uart_putc
uart_putc:
	bx		lr

	.global uart_getc
uart_getc:
	mov		r0, #0
	bx		lr
