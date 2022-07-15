echo "Cleaning build/*..."
rm -rf ./build/*
echo "Building sources..."
nasm -f bin ./source/boot.asm -o ./build/boot.bin
nasm -f bin ./source/sysinit.asm -o ./build/sysinit.bin
echo "Writing boot.bin..."
dd if=/dev/zero of=./build/pushos.img bs=1M count=1
echo "Empty img created."
dd if=./build/boot.bin of=./build/pushos.img seek=0 bs=512 conv=notrunc
echo "boot.bin written"
dd if=./build/sysinit.bin of=./build/pushos.img seek=1 bs=512 conv=notrunc
echo "boot.bin written"
