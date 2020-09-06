.PHONY: all clean run

ASMSRCS = plaid.S uart.S
ASMOBJS = $(ASMSRCS:.S=.o)

CFLAGS=-mcpu=cortex-a53 -g -O0 -fpic -ffreestanding -std=gnu99 

all: kernel7.img

%.o: %.S
	arm-none-eabi-gcc $(CFLAGS) -c -o $@ $<

kernel7.img: $(ASMOBJS)
	arm-none-eabi-gcc -T linker.ld -o kernel7.elf -ffreestanding -O0 -g -nostdlib $(ASMOBJS) -lgcc
	arm-none-eabi-objcopy kernel7.elf -O binary kernel7.img

clean:
	rm -f *.o *.elf *.img

run:
