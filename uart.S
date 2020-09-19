.equ    PERIPHBASE, 0x3F000000
.equ    UARTBASE,   (PERIPHBASE + 0x00201000)

// offsets
.equ    UART_DR,     0x00
.equ    UART_RSRECR, 0x04
.equ    UART_FR,     0x18
.equ    UART_ILPR,   0x20
.equ    UART_IBRD,   0x24
.equ    UART_FBRD,   0x28
.equ    UART_LCRH,   0x2c
.equ    UART_CR,     0x30
.equ    UART_IFLS,   0x34
.equ    UART_IMSC,   0x38
.equ    UART_RIS,    0x3c
.equ    UART_MIS,    0x40
.equ    UART_ICR,    0x44
.equ    UART_DMACR,  0x48
.equ    UART_ITCR,   0x80
.equ    UART_ITIP,   0x84
.equ    UART_ITOP,   0x88
.equ    UART_TDR,    0x8c

// error condition bits
.equ    UART_OE, (1<<11) // overrun
.equ    UART_BE, (1<<10) // break
.equ    UART_PE, (1<<9)  // parity
.equ    UART_FE, (1<<8)  // framing error

// flag bits
.equ    UART_RI,   (1<<8)  // ring indicator (unsupported)
.equ    UART_TXFE, (1<<7)  // transmit FIFO empty
.equ    UART_RXFF, (1<<6)  // receive FIFO full
.equ    UART_TXFF, (1<<5)  // transmit FIFO full
.equ    UART_RXFE, (1<<4)  // receive FIFO empty
.equ    UART_BUSY, (1<<3)  // UART is busy
.equ    UART_DCD,  (1<<2)  // data carrier detect (unsupported)
.equ    UART_DSR,  (1<<1)  // data set ready (unsupported)
.equ    UART_CTS,  (1<<0)  // clear to send

// line control register bits
.equ    UART_SPS,    (1<<7)   // enable stick parity
.equ    UART_WLEN1,  (1<<6)   // MSB of word length
.equ    UART_WLEN0,  (1<<5)   // LSB of word length
.equ    UART_FEN,    (1<<4)   // enable FIFOs
.equ    UART_STP2,   (1<<3)   // use two stop bits
.equ    UART_EPS,    (1<<2)   // even parity
.equ    UART_PEN,    (1<<1)   // enable parity
.equ    UART_BRK,    (1<<0)   // send break

// control bits
.equ    UART_CTSEN,  (1<<15)  // CTS enabled
.equ    UART_RTSEN,  (1<<14)  // RTS enabled
.equ    UART_OUT2,   (1<<13)  // unsupported
.equ    UART_OUT1,   (1<<12)  // unsupported
.equ    UART_RTS,    (1<<11)  // request to send
.equ    UART_DTR,    (1<<10)  // data terminal ready (unsupported)
.equ    UART_RXE,    (1<<9)   // enable receiver
.equ    UART_TXE,    (1<<8)   // enable transmitter
.equ    UART_LBE,    (1<<7)   // enable loopback
.equ    UART_SIRLP,  (1<<2)   // unsupported
.equ    UART_SIREN,  (1<<1)   // unsupported
.equ    UART_UARTEN, (1<<0)   // enable UART

    .text
    .align  2
    .global uart_init
uart_init:
    ldr     x1, =UARTBASE
    // set baud rate divisor
    // (3 mHz / ( 115200 * 16 )) = 1.62760416667
    // = 1.101000 in binary
    mov     w0, #1
    str     w0, [x1, #UART_IBRD]
    mov     w0, #0x28
    str     w0, [x1, #UART_FBRD]
    // set parity, word length, enable FIFOs
    .equ    BITS, (UART_WLEN1|UART_WLEN0|UART_FEN|UART_STP2)
    mov     w0, #BITS
    str     w0, [x1, #UART_LCRH]
    // mask all interrupts
    mov     w0, #0
    str     w0, [x1, #UART_IMSC]
    // enable receiver and transmitter and UART
    .equ    FINALBITS, (UART_RXE|UART_TXE|UART_UARTEN)
    ldr     w0, =FINALBITS
    str     w0, [x1, #UART_CR]
    // done
    ret

    .text
    .align  2
    .global uart_putc
uart_putc:
    ldr     x1, =UARTBASE
putlp:
    ldr     x2, [x1, #UART_FR]
    tst     x2, #UART_TXFF
    bne     putlp
    str     x0, [x1, #UART_DR]
    ret

    .text
    .align  2
    .global uart_getc
uart_getc:
    ldr     x1, =UARTBASE
getlp:
    ldr     x2, [x1, #UART_FR]
    tst     x2, #UART_RXFE
    bne     getlp
    ldr     w0, [x1, #UART_DR]
    tst     w0, #UART_OE
    bne     get_ok1
get_ok1:
    tst     w0, #UART_BE
    bne     get_ok2
get_ok2:
    tst     w0, #UART_PE
    bne     get_ok3
get_ok3:
    tst     w0, #UART_FE
    bne     get_ok4
get_ok4:
    ret