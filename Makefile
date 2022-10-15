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

all: KernelImage.bin

vmdk:
	$(QEMU_IMG) convert -f raw -O vmdk KernelImage.bin Kernel.vmdk

# Kernel.bin: boot.bin sysinit.bin
KernelImage.bin: boot.bin
	$(DD) if=/dev/zero of=$@ bs=18M count=1
	$(DD) if=boot.bin of=KernelImage.bin seek=0 bs=16M conv=notrunc

boot.bin: kloader.bin source/boot.asm
	$(NASM) -f bin -o boot.bin source/boot.asm

kloader.bin: source/kloader.asm
	$(NASM) -f bin -o kloader.bin source/kloader.asm

sysinit.bin: source/sysinit.asm
	$(NASM) -f bin -o sysinit.bin source/sysinit.asm

clean:
	rm -f ./*.bin
	rm -f ./*.o
	rm -f ./*.elf
	rm -f ./*.vmdk
