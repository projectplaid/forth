.PHONY: all clean run

ASMSRCS = boot.S plaid.S
ASMOBJS = $(ASMSRCS:.S=.o)

CSRCS = uart.c
COBJS = $(CSRCS:.c=.o)

CFLAGS=-mcpu=cortex-a53 -g -O0 -fpic -ffreestanding -std=gnu99 

all: kernel7.img

%.o: %.S
	arm-none-eabi-gcc $(CFLAGS) -c -o $@ $<

%.o: %.c
	arm-none-eabi-gcc $(CFLAGS) -c -o $@ $<

kernel7.img: $(ASMOBJS) $(COBJS)
	arm-none-eabi-gcc -T linker.ld -o kernel7.elf -ffreestanding -O0 -g -nostdlib $(ASMOBJS) $(COBJS) -lgcc
	arm-none-eabi-objcopy kernel7.elf -O binary kernel7.img

clean:
	rm -f *.o *.elf *.img

run:
