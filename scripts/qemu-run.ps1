# qemu-system-i386.exe -m 1024M -serial stdio -vga virtio -drive file=./Kernel.bin,format=raw,index=0,if=floppy -gdb tcp:localhost:23946 -S
qemu-system-i386.exe -m 1024M -serial stdio -vga virtio -hda Kernel.vmdk
