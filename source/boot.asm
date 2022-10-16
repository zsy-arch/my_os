org 0000h
bits 16
section .text

;Disk Address Packet
struc DAP
    .PacketSize 	resb 1
    .Reserved 		resb 1
    .BlockCount 	resw 1
    .BufferOffset 	resw 1
    .BufferSegment 	resw 1
    .LBNLow 		resd 1
    .LBNHigh 		resd 1
endstruc

%define KLOADER_LBNLOW (08h)
%define KLOADER_BLOCKCOUNT (010h)

start:
    nop
    nop
    mov ax, 07c0h
    mov ds, ax
    mov ax, 0800h
    mov es, ax
    mov cx, 200h
    xor si, si
    xor di, di
    rep movsb
    jmp 0800h:(go - start)
go:
    mov ax, 0800h
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov sp, 0fffh
load_sysinit:
    mov ah, 0h
    mov al, 02h
    int 10h
    lea di, [welcome_string]
    push di
    call k_puts

    call read_sysinit
    jc .load_failed
    lea di, [ok_string]
    push di
    call k_puts
    jmp 0h:0100h
.load_failed:
    lea di, [error_string]
    push di
    call k_puts
    jmp $

read_sysinit:
    push bp
    mov bp, sp
    push bx
    push es
    push si
    sub sp, 10h
    mov si, sp
    mov byte [si+DAP.PacketSize], 10h
    mov byte [si+DAP.Reserved], 0h
    mov word [si+DAP.BlockCount], KLOADER_BLOCKCOUNT
    mov word [si+DAP.BufferOffset], 0100h
    mov word [si+DAP.BufferSegment], 0h
    mov dword [si+DAP.LBNLow], KLOADER_LBNLOW
    mov dword [si+DAP.LBNHigh], 0h
    mov ah, 42h
    mov dl, 80h
    int 13h
    add sp, 10h
    pop si
    pop es
    pop bx
    pop bp
    ret
k_puts:
    push bp
    mov bp, sp
    push di
    push bx
    push ax
    mov bh, 00h
    lea di, [bp+04h]
    mov di, ds:[di]
    mov ah, 0Eh
.repeat:
    mov al, ds:[di]
    cmp al, 0
    je .done
    int 10h
    inc di
    jmp .repeat
.done:
    pop ax
    pop bx
    pop di
    pop bp
    ret 02h

welcome_string:
    db "Welcome to JuanOS...", 0h
ok_string:
    db "Ok", 0h
error_string:
    db "Oops", 0h
    times 510-64-($-$$) db 0
    db  80h
    db  00
    db  02
    db  00
    db  07
    db  08
    db  08
    db  32
    dd  00000001h
    dd  00007fffh
    times 510 - ($ - $$) db 0
    dw 0AA55h
;------------------------------------------------------
    db 0,0,0      ;UCHAR     Jump[3];			// 0x00
    db  "NTFS    " ;UCHAR     OEMID[8];			// 0x03
    ;typedef struct _BIOS_PARAMETERS_BLOCK
    ;{
        dw 512;USHORT    BytesPerSector;		// 0x0B
        db 8;UCHAR     SectorsPerCluster;		// 0x0D
        db 0,0,0,0,0,0,0;UCHAR     Unused0[7];	// 0x0E, checked when volume is mounted
        db 12;UCHAR     MediaId;				// 0x15, 11=RemovableMedia  12=FixedMedia
        db 0,0;UCHAR     Unused1[2];			// 0x16
        dw 15;USHORT    SectorsPerTrack;		// 0x18
        dw 0;USHORT    Heads;					// 0x1A
        db 0,0,0,0;UCHAR     Unused2[4];		// 0x1C
        db 0,0,0,0;UCHAR     Unused3[4];		// 0x20, checked when volume is mounted
    ;} BIOS_PARAMETERS_BLOCK, *PBIOS_PARAMETERS_BLOCK;
    
    ;typedef struct _EXTENDED_BIOS_PARAMETERS_BLOCK
    ;{
        dw 0,0;USHORT    Unknown[2];			// 0x24, always 80 00 80 00
        dq 07fffh;ULONGLONG SectorCount;		// 0x28
        dq 0;ULONGLONG MftLocation;				// 0x30
        dq 0;ULONGLONG MftMirrLocation;			// 0x38
        db 0;CHAR      ClustersPerMftRecord;	// 0x40
        db 0,0,0;UCHAR     Unused4[3];			// 0x41
        db 0;CHAR      ClustersPerIndexRecord;	// 0x44
        db 0,0,0;UCHAR     Unused5[3];			// 0x45
        dq 0;ULONGLONG SerialNumber;			// 0x48
        db 0,0,0,0;UCHAR     Checksum[4];		// 0x50
    ;} EXTENDED_BIOS_PARAMETERS_BLOCK, *PEXTENDED_BIOS_PARAMETERS_BLOCK;

times 1022-($-$$) db 0
    dw  0AA55h
;------------------------------------------------------
times 1000h-($-$$) db 0
KLOADER_START:
incbin "./kloader.bin"
KLOADER_END: align 10h
times 2000h-($-$$) db 0
;------------------------------------------------------
; incbin "./main.bin"
; times 4000h-($-$$) db 0
times 80000h - 3 -($-$$) db 0
db 0EEh, 0h, 0FFh
;------------------------------------------------------