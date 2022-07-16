org 0x9000
bits 16
start:
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
	db "System started successfully.", 0Ah, 0Dh, 0h