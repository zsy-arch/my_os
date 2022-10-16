#!/bin/sh
qemu-system-i386 -m 1024M -serial stdio -vga virtio -hda ./Kernel.vmdk -s -S
