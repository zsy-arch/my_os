CC = gcc
NASM = nasm
AS = as
LD = ld
OBJDUMP = objdump
OBJCOPY = objcopy
PY = python3
DD = dd
BUILD_TOOL = scripts/build.py
QEMU_IMG = qemu-img

all: Kernel.bin

vmdk:
	$(QEMU_IMG) convert -f raw -O vmdk Kernel.bin Kernel.vmdk

# Kernel.bin: boot.bin sysinit.bin
Kernel.bin: sysinit.bin boot.bin
	$(DD) if=/dev/zero of=$@ bs=18M count=1
	$(DD) if=boot.bin of=Kernel.bin seek=0 bs=16M conv=notrunc

boot.bin: source/boot.asm source/boot.c
	# $(NASM) -f elf32 -o boot.asm.o source/boot.asm
	# $(CC) -m16 -g -Os -ffreestanding -nostdinc -c source/boot.c -o boot.c.o
	# $(LD) -melf_i386 --build-id=none -T scripts/boot.link.ld boot.asm.o boot.c.o -o boot.elf
	# $(OBJCOPY) -O binary boot.elf boot.bin
	$(NASM) -f bin -o boot.bin source/boot.asm

sysinit.bin: source/sysinit.asm
	$(NASM) -f bin -o $@ $^

clean:
	rm -f ./*.bin
	rm -f ./*.o
	rm -f ./*.elf
	rm -f ./*.vmdk
