org 7C00h
bits 16
; boot.bin 由 boot.asm 汇编得到. 负责加载 sysinit.bin 到 0x40000
start:
	cli
	xor ax, ax
	mov ss, ax
	mov sp, 7c00h
	mov ax, 7e0h
	mov es, ax
	sti
	mov si, welcome_string
	call k_puts
load_sysinit:
	mov dx, 0h
	mov cx, 0002h
	mov bx, 0h
	mov ax, 0201h
	int 13h
	jnc ok_load_sysinit
	mov dx, 0h
	mov ax, 0h
	int 13h
	jmp load_sysinit
ok_load_sysinit:
	mov si, load_init_ok1
	call k_puts
k_loop:
	jmp k_loop


k_puts:
	mov ah, 0Eh
.repeat:
	lodsb
	cmp al, 0
	je .done
	int 10h
	jmp .repeat
.done:
	ret
data:
welcome_string:
	db "Loading ZSY-ARCH OS(v0.0.1)...", 0Ah, 0Dh, 0h
load_init_ok1:
	db "Loading SysInit Module...", 0Ah, 0Dh, 0h
load_init_retry:
	db "Loading SysInit Module(Retry)...", 0Ah, 0Dh, 0h
times 510 - ($ - $$) db 0
dw 0xAA55
