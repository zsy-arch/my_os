org 7C00h
bits 16
section .text
; boot.bin 由 boot.asm 汇编得到. 负责加载 sysinit.bin 到 8000:0200

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

struc SectorFrame
	.DriveNum	resd 1
	.LBNLow 	resd 1
	.LBNHigh 	resd 1
	.BlockCount resd 1
	.Buffer 	resd 1
	.ReadWrite 	resd 1
endstruc

%define DriveNum_SYSINIT 08h
%define BlockCount_SYSINIT (2000h - 1000h) / 512
%define Buffer_SYSINIT (80200h)

%define DriveNum_MAIN 10h
%define BlockCount_MAIN (4000h - 2000h) / 512
%define Buffer_MAIN (10000h)

start:
	; 把当前扇区复制到 8000:0000
	mov ax, 07c0h
	mov ds, ax
	mov ax, 8000h
	mov es, ax
	mov cx, 200h
	xor si, si
	xor di, di
	rep movsb
	; 跳转到 8000:go
	jmp 8000h:(go - start)
go:
	cli
	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov sp, 7c00h
	sti
load_sysinit:
	; 加载 sysinit 到 8000:0200 (80200h)
	push dword BlockCount_SYSINIT
	push dword DriveNum_SYSINIT
	push dword Buffer_SYSINIT		; dest 8000:0200
	call k_loadsector
	; 加载失败
	jc .load_failed
	push dword BlockCount_MAIN
	push dword DriveNum_MAIN
	push dword Buffer_MAIN		; dest 0000:0000
	call k_loadsector
	jc .load_failed
	push word 8000h 				; segment
	push word 0200h					; offset
	retf
	; jmp 8000:0200
.load_failed:
; push 0x401000
; ret

; jmp 0x401000
k_loop:
	jmp k_loop

k_loadsector:
;{
	push  ebp  
	mov  ebp, esp 
	sub  esp, 0E4h 
	push  ebx  
	push  esi  
	push  edi  
	
	;int run = count / 64;
	mov  eax,dword [ebp+0Eh] 
	cdq              
	and  edx, 3Fh 
	add  eax, edx 
	sar  eax, 6 
	mov  dword [ebp-8], eax 
	
	;int mod = count % 64;
	mov  eax, dword [ebp+0Eh] 
	and  eax, 8000003Fh 
	jns  .set_mod
	dec  eax  
	or  eax,0FFFFFFC0h 
	inc  eax  
	
.set_mod: 
	mov  dword [ebp-14h], eax 

	;for(int i=0; i<run; i++)
	mov  dword [ebp-20h], 0 
	jmp  _read
	
_loop:
	mov  eax,dword [ebp-20h] 
	add  eax,1 
	mov  dword [ebp-20h],eax 
_read:   
    mov  eax,dword [ebp-20h] 
	cmp  eax,dword [ebp-8] 
	jge  _left
	;{
	;ReadWriteSector(0x80, src, 0, 64, des, 0x42);
	push  dword 42h
	mov  eax, dword [ebp+6] 
	push  eax  
	push  dword 40h  
	push  dword 0    
	mov  ecx, dword [ebp+0Ah] 
	push  ecx  
	push  dword 80h  
	call  k_readsector
	add  esp, 24 

	;src = src + 64;
	mov  eax, dword [ebp+0Ah] 
	add  eax, 40h 
	mov  dword [ebp+0Ah], eax 
	;des = des + 64*512;
	mov  eax, dword [ebp+6] 
	add  eax, 8000h 
	mov  dword [ebp+6], eax 
	;}
	jmp  _loop

	;if(mod)
_left:
	cmp  dword [ebp-14h],0           
    je  .return
	;{
		;ReadWriteSector(0x80, src, 0, mod, des, 0x42);
	push  dword 42h	
	mov  eax, dword [ebp+6] 
	push  eax  
	mov  ecx, dword [ebp-14h] 
	push  ecx  
	push  dword 0    
	mov  edx, dword [ebp+0Ah] 
	push  edx  
	push  dword 80h  
	call  k_readsector
	add  esp, 24
	;}
;}
.return:   
    pop  edi  
	pop  esi  
	pop  ebx  
	add  esp, 0E4h 
	mov  esp, ebp 
	pop  ebp  
	ret 12

k_readsector:
	push  bp
    mov  bp, sp
    add  bp, 4

    push  ds
    push  si
    push  bx
	
    push  0
    pop  ds
    	
	sub  sp, 16
	mov  si, sp
	mov  byte [si+DAP.PacketSize], 10h        
	mov  byte [si+DAP.Reserved], 0          
	mov  al,byte [bp+SectorFrame.BlockCount]
	mov  byte[si+DAP.BlockCount], al           
	mov  byte[si+DAP.BlockCount+1], 0         
	mov  eax, dword[bp+SectorFrame.Buffer]
    mov  bx, ax
    and  bx, 0fh     
    mov  word[si+DAP.BufferOffset], bx        
    shr  eax, 4
    mov  word[si+DAP.BufferSegment], ax        
    mov  eax, dword[bp+SectorFrame.LBNLow]
    mov  dword[si+DAP.LBNLow], eax            
    mov  eax, dword[bp+SectorFrame.LBNHigh]
    mov  dword[si+DAP.LBNHigh], eax            

    mov  ah, byte [bp+SectorFrame.ReadWrite]                                          
    mov  dl, byte [bp+SectorFrame.DriveNum]          
    int  13h
    jc   .error

    xor  eax, eax
.error:

    and  eax, 0000ffffh
            
	add  sp, 16
	pop  bx
	pop  si
	pop  ds
	
	pop  bp
	retn

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
; 以下两行 使用GCC -m16时不使用
times 510 - ($ - $$) db 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dw 0AA55h
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

times 1000h-($-$$) db 0
SYSINIT_START:
incbin "./sysinit.bin"
SYSINIT_END: align 10h
times 2000h-($-$$) db 0
dw 0AABBh
; incbin "./main.bin"
; times 4000h-($-$$) db 0
times 80000h - 3 -($-$$) db 0
db 0EEh, 0h, 0FFh