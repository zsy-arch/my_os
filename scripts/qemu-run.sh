#!/bin/sh
qemu-system-i386.exe -m 1024M -serial stdio -vga virtio -drive file=./Kernel.bin,format=raw