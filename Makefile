CC = gcc
NASM = nasm
PY = python3
BUILD_TOOL = scripts/build.py
DD = dd

all: Kernel.bin

Kernel.bin: boot.bin sysinit.bin
	# $(PY) $(BUILD_TOOL) -o $@ $^
	$(DD) if=/dev/zero of=$@ bs=1M count=1
	$(DD) if=boot.bin of=Kernel.bin seek=0 bs=512 conv=notrunc
	$(DD) if=sysinit.bin of=Kernel.bin seek=1 bs=512 conv=notrunc

boot.bin: source/boot.asm
	$(NASM) -f bin -o $@ $^

sysinit.bin: source/sysinit.asm
	$(NASM) -f bin -o $@ $^

clean:
	rm -f ./*.bin
