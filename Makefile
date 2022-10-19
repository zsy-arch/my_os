# ARCH = riscv64 | x86_64
ARCH ?= riscv64
# sudo apt install gcc-riscv64-unknown-elf
ifeq ($(ARCH), riscv64)
	CC = riscv64-unknown-elf-gcc
endif
ifeq ($(ARCH), x86_64)
	CC = x86_64-linux-gnu-gcc
endif
CFLAGS = -mcmodel=medium -std=gnu99 -Wno-unused -Werror -fno-builtin -Wall -O2 -nostdinc -fno-stack-protector -ffunction-sections -fdata-sections -c
NASM = nasm
AS = as
LD = ld
OBJCOPY := $(GCCPREFIX)objcopy
OBJDUMP := $(GCCPREFIX)objdump
PY = python3
DD = dd
QEMU_IMG = qemu-img
OUTPUT_DIR = ./build
QEMU := qemu-system-$(ARCH)

all: kernel

vmdk:
	$(QEMU_IMG) convert -f raw -O vmdk $(OUTPUT_DIR)/kernel $(OUTPUT_DIR)/kernel.vmdk

kernel: boot.bin
	$(DD) if=/dev/zero of=$(OUTPUT_DIR)/kernel bs=18M count=1
	$(DD) if=$(OUTPUT_DIR)/boot.bin of=$(OUTPUT_DIR)/kernel seek=0 bs=16M conv=notrunc

boot.bin: kernel.bin kloader.bin source/arch/$(ARCH)/boot.asm
	$(NASM) -f bin -o $(OUTPUT_DIR)/boot.bin source/arch/$(ARCH)/boot.asm

kloader.bin: source/arch/$(ARCH)/kloader.asm
	$(NASM) -f bin -o $(OUTPUT_DIR)/kloader.bin source/arch/$(ARCH)/kloader.asm

kernel.bin: source/kernel/kernel.c scripts/kernel.link.ld
	$(CC) $(CFLAGS) source/kernel/kernel.c -o $(OUTPUT_DIR)/kernel.o
	$(LD) -T scripts/kernel.link.ld $(OUTPUT_DIR)/kernel.o -o $(OUTPUT_DIR)/kernel.bin

clean:
	rm -f $(OUTPUT_DIR)/*.bin
	rm -f $(OUTPUT_DIR)/*.o
	rm -f $(OUTPUT_DIR)/*.elf
	rm -f $(OUTPUT_DIR)/*.vmdk
