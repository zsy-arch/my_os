org 0100h

[bits 16]

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

%include "./source/boot/dap.asm"
%include "./source/boot/seg.asm"