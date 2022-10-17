org 0100h

[bits 16]

struc DAP
	.PacketSize 	resb 1
	.Reserved 		resb 1
	.BlockCount 	resw 1
	.BufferOffset 	resw 1
	.BufferSegment 	resw 1
	.LBNLow 		resd 1
	.LBNHigh 		resd 1
endstruc

struc SectorFrame
	.DriveNum	resd 1
	.LBNLow 	resd 1
	.LBNHigh 	resd 1
	.BlockCount resd 1
	.Buffer 	resd 1
	.ReadWrite 	resd 1
endstruc
KLOADER_BASE  equ 0100h
KL_CS equ 018h

%define PROTECT_MODE  0001h
%define ENABLE_PAGING (1h << 31)
start:
	nop
	nop
	nop
	nop
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov ax, 8fffh
	mov sp, ax
	sti
	jmp init_main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_main:
	call k_init_protected_mode
go_main:
	nop
	jmp go_main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
k_init_protected_mode:
	cli
	call k_enable_a20
    call k_enable_protection_paging
.done:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
k_enable_a20:
	call empty_8042
	mov al, 0d1h
	out 064h, al
	call empty_8042
	mov al, 0dfh
	out 060h, al
	call empty_8042
	ret
empty_8042:
    jmp $+2
    jmp $+2
	in al, 064h
	test al, 02h
	jnz empty_8042
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
k_enable_protection_paging:
    push dword 0h
    popfd
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    lgdt [GDT_Reg]
    lidt [IDT_Reg]
	push eax
	mov ax, [GDT_Reg]
	mov eax, [GDT_Reg + 02h]
	pop eax
    mov eax, cr0
    or eax, PROTECT_MODE
    mov cr0, eax
.go_pm:
	push word KL_CS
	push word .ok
    retf
.ok:
	nop
	jmp .ok
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;G|D/B|L|AVL|Segment limit 19:16
%define G_0   00h  ;0000 0000
%define G_1   80h  ;1000 0000

%define DB_16 00h  ;0000 0000
%define DB_32 40h  ;0100 0000

%define L_0   00h  ;0000 0000
%define L_1   20h  ;0010 0000

%define AVL_0 00h  ;0000 0000
%define AVL_1 10h  ;0001 0000

;P|DPL|S|Type
%define P_0   00h  ;0000 0000
%define P_1   80h  ;1000 0000

%define DPL_0 00h  ;0000 0000
%define DPL_3 60h  ;0110 0000

%define S_0   00h  ;0000 0000
%define S_1   10h  ;0001 0000


;S=1
%define DataType0(Read_Only)                         00h  ;0000 0000
%define DataType1(Read_Only_accessed)                01h  ;0000 0001
%define DataType2(Read_Write)                        02h  ;0000 0010
%define DataType3(Read_Write_accessed)               03h  ;0000 0011
%define DataType4(Read_Only_expand_down)             04h  ;0000 0100
%define DataType5(Read_Only_expand_down_accessed)    05h  ;0000 0101
%define DataType6(Read_Write_expand_down)            06h  ;0000 0110
%define DataType7(Read_Write_expand_down_accessed)   07h  ;0000 0111
%define CodeType8(Execute_Only)                      08h  ;0000 1000
%define CodeType9(Execute_Only_accessed)             09h  ;0000 1001
%define CodeType10(Execute_Read)                     0Ah  ;0000 1010
%define CodeType11(Execute_Read_accessed)            0Bh  ;0000 1011
%define CodeType12(Execute_Only_conforming)          0Ch  ;0000 1100
%define CodeType13(Execute_Only_conforming_accessed) 0Dh  ;0000 1101
%define CodeType14(Execute_Read_conforming)          0Eh  ;0000 1110
%define CodeType15(Execute_Read_conforming_accessed) 0Fh  ;0000 1111

;S=0
%define SystemType0(Reserved)                        00h  ;0000 0000
%define SystemType1(_16_bit_TSS_Available)           01h  ;0000 0001
%define SystemType2(LDT)                             02h  ;0000 0010
%define SystemType3(_16_bit_TSS_Busy)                03h  ;0000 0011
%define SystemType4(_16_bit_Call_Gate)               04h  ;0000 0100
%define SystemType5(Task_Gate)                       05h  ;0000 0101
%define SystemType6(_16_bit_Interrupt_Gate)          06h  ;0000 0110
%define SystemType7(_16_bit_Trap_Gate)               07h  ;0000 0111
%define SystemType8(Reserved)                        08h  ;0000 1000
%define SystemType9(_32_bit_TSS_Available)           09h  ;0000 1001
%define SystemType10(Reserved)                       0Ah  ;0000 1010
%define SystemType11(_32_bit_TSS_Busy)               0Bh  ;0000 1011
%define SystemType12(_32_bit_Call_Gate)              0Ch  ;0000 1100
%define SystemType13(Reserved)                       0Dh  ;0000 1101
%define SystemType14(_32_bit_Interrupt_Gate)         0Eh  ;0000 1110
%define SystemType15(_32_bit_Trap_Gate)              0Fh  ;0000 1111

%macro GDTDesc 6
    dw %6  ;Segment limit 15:00
    dw %5  ;Base Address 15:00
    db %4  ;Base Address 23:16
    db %3  ;P|DPL|S|Type
    db %2  ;G|D/B|L|AVL|Segment limit 19:16
    db %1  ;Base 31:24
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GDT_begin:
GDTDesc 00h, 00h, 00h, 00h, 0000h, 0000h

GDTDesc 00h, G_1|DB_32|L_0|AVL_0|0fh, P_1|DPL_0|S_1|CodeType10(Execute_Read), 00h, 0000h, 0ffffh

GDTDesc 00h, G_1|DB_32|L_0|AVL_0|0fh, P_1|DPL_0|S_1|DataType2(Read_Write), 00h, 0000h, 0ffffh

GDTDesc 00h, G_1|DB_16|L_0|AVL_0|0fh, P_1|DPL_0|S_1|CodeType10(Execute_Read), 00h, 0000h, 0ffffh

times GDT_begin + 1024 - $ db 0
GDT_end:

IDT_begin:
	times 256 dq 0	
IDT_end:

GDT_Reg:
    dw GDT_end - GDT_begin - 1
    dd GDT_begin

IDT_Reg:
	dw	IDT_end - IDT_begin - 1
	dd	IDT_begin
