.PHONY: all clean run

# plaid.S
ASMSRCS = boot.S  uart.S
ASMOBJS = $(ASMSRCS:.S=.o)

CSRCS = 
COBJS = $(CSRCS:.c=.o)

CFLAGS=-mcpu=cortex-a53 -g -O0 -fpic -ffreestanding -std=gnu99 

all: kernel8.img

%.o: %.S
	aarch64-none-elf-gcc $(CFLAGS) -c -o $@ $<

%.o: %.c
	aarch64-none-elf-gcc $(CFLAGS) -c -o $@ $<

kernel8.img: $(ASMOBJS) $(COBJS)
	aarch64-none-elf-gcc -T linker.ld -o kernel8.elf -ffreestanding -O0 -g -nostdlib $(ASMOBJS) $(COBJS) -lgcc
	aarch64-none-elf-objcopy kernel8.elf -O binary kernel8.img

clean:
	rm -f *.o *.elf *.img

run:
