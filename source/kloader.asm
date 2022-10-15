org 0100h

bits 16

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

; 电脑启动，ip=0x7c00
; 写代码，编译 => 放硬盘第一个扇区
; 布局
; 0000:0000 - 之后用于存放 main.bin
; 3000:0000 - 之后用于存放系统信息
; 4000:0000 - 之前用于栈
; 4000:0000 - 4000:ffff 存放 sysinit 代码
;
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
welcome_string:
	db "System loaded successfully...", 0Ah, 0Dh, 0h
pm_string:
	db "System started successfully...", 0Ah, 0Dh, 0h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_main:
	lea si, [welcome_string]
	push si
	; 输出 loaded successfully
	call k_puts
	; 实模式 -> 保护模式
	call k_init_protected_mode
	; 输出 started successfully
	lea si, [pm_string]
	push si
	call k_puts
	jmp k_loop
k_loop:
	nop
	jmp k_loop
k_init_protected_mode:
	push bp
	push si
	push ds
	mov bp, sp
	; 正式开始准备进入保护模式
	cli
	; 开启 A20
	call k_enable_a20
	; 加载 GDT/IDT (segment descriptor)
	call k_loadsd
	sti
.done:
	pop ds
	pop si
	pop bp
	ret

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
	jmp $+3
	jmp $+3
	in al, 064h
	test al, 02h
	jnz empty_8042
	ret

k_loadsd:

	ret

k_puts:
	push bp
	mov bp, sp
	add bp, 04h
	mov bp, [bp]
	mov ah, 0Eh
.repeat:
	mov al, ds:[bp]
	cmp al, 0
	je .done
	int 10h
	inc bp
	jmp .repeat
.done:
	pop bp
	ret 02h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GDT
%macro GDTDesc 6
	dw %6 	; 段限长1
	dw %5	; 段基址1
	db %4	; 段基址2
	db %3	; P|DPL|S|Type
	db %2	; G|D/B|L|AVL|段限长2
	db %1	; 段基址3
%endmacro
; G = 0 => 1B ~ 1MB	; G = 1 => 4K ~ 4GB
%define G_0 00h
%define G_1 80h

; S = 0 => 系统段 ; S = 1 => 代码段或者是数据段
%define S_0 00h
%define S_1 10h

;;;;;Type;;;;;
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

; P = 1 => 段存在于内存中 ; P = 0 => 不存在
%define P_0 00h
%define P_0 80h

; L = 1 => 64 位模式 ; L = 0 => 兼容模式
%define L_0   00h  ;0000 0000
%define L_1   20h  ;0010 0000

; D = 1 => 使用32位地址、32/8 位操作数 ; D = 0 => 使用16位地址、16/8 位操作数
; B = 1 => 使用 32 位栈指针 ; B = 0 使用 16 位栈指针
%define DB_16 00h  ;0000 0000
%define DB_32 40h  ;0100 0000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


