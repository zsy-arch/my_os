org 0x7C00
bits 16
start:
	cli
	xor ax, ax
	mov ss, ax
	mov sp, 7c00h
	sti
	mov si, welcome_string
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
times 510 - ($ - $$) db 0
dw 0xAA55
