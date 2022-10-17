OUTPUT_FORMAT("elf64-x86-64");
/* We define an entry point to keep the linker quiet. This entry point
 * has no meaning with a bootloader in the binary image we will eventually
 * generate. Bootloader will start executing at whatever is at 0x07c00 */
ENTRY(main);
SECTIONS
{
    . = 0x100000;
    .text : {
        /* Place the code in boot.asm.o before all other code */
        kernel.o(.text);
        *(.text);
    }

    /* Place the data after the code */
    .data : SUBALIGN(2) {
        kernel.o(.data);
        kernel.o(.rodata*);
    }

    /* Place the uninitialised data in the area after our bootloader
     * The BIOS only reads the 512 bytes before this into memory */
    .bss : SUBALIGN(4) {
        __bss_start = .;
        *(COMMON);
        *(.bss)
        . = ALIGN(4);
        __bss_end = .;
    }
    __bss_sizeb = SIZEOF(.bss);

    /* Remove sections that won't be relevant to us */
    /*/DISCARD/ : {
        *(.eh_frame);
        *(.comment);
    }*/
}