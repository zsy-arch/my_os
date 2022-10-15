#!/bin/sh
qemu-system-i386 -m 1024M -serial stdio -vga virtio -drive file=./KernelImage.bin,format=raw
