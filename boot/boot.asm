; Boot Sector
; Jacob Runge - 6/24/2016

[bits 16]
[org 0x7c00]

; Constants
KERNEL_OFFSET equ 0x1000		; Memory offset where we load our kernel

; Code entry / Real Mode block
start:
	;Print Real Mode load message
	mov bx, MSG_REAL_LOAD
	call print_string_16
	
	;Load kernel
	mov [BOOT_DRIVE], dl		; BIOS stores boot drive in dl - remember for later
	call load_kernel			; load the kernel

	jmp switch_to_pm

; 16-bit string printing function
; load bx with address of null-terminating string prior to call
; uses ax, bx
print_string_16:
	mov ah, 0x0e				; BIOS code to print teletype
	
	.loop:						; Iterate over addresses starting at bx
		mov al, [bx]
		int 0x10				; BIOS interrupt - print teletype in al
		
		inc bx
		cmp [bx], byte 0		; Compare new [bx] to 0; terminate string if 0
		jne .loop
		
	ret
		
; 16-bit kernel loader
load_kernel:
	mov bx, MSG_LOAD_KERNEL
	call print_string_16
	
	mov bx, KERNEL_OFFSET		; Set up parameters for disk routine
	mov dh, 4					; Load 15 sectors (excluding boot sector) from disk to KERNEL_OFFSET in memory
	mov dl, [BOOT_DRIVE]
	call disk_load_16
	
	ret

; Disk read function - 16-bit
; loads dh sectors to es:bx from drive dl
; uses ax, bx, cx, dx
disk_load_16:
	push dx			;store dx on stack for later recall - # sectors requested to be read
	
	mov ah, 0x02	;BIOS read sector function
	mov al, dh		;Read dh sectors
	mov ch, 0x00	;Select cylinder 0
	mov dh, 0x00	;Select head 0
	mov cl, 0x02	;Start reading from second sector (after boot sector)
	
	int 0x13		;BIOS read disk interrupt
	
	jc disk_error_general	;if carry flag, jump to error
	
	pop dx			;restore dx
	cmp dh, al		;if sectors read != dh (sectors expected)
	jne disk_error_mismatch
	ret
	
disk_error_general:
	mov bx, DISK_ERROR_GENERAL
	call print_string_16
	jmp $
	
disk_error_mismatch:
	mov bx, DISK_ERROR_MISMATCH
	call print_string_16
	jmp $
	
	DISK_ERROR_GENERAL: db "Disk read error - general fault.", 0
	DISK_ERROR_MISMATCH: db "Disk read error - sector specification/read mismatch.", 0

; Switch to Protected Mode
switch_to_pm:

	cli		;must switch off interrupts until protected mode interrupt vector is set up
	
	lgdt[gdt_descriptor]	; load global descriptor table
	
	mov eax, cr0			; set first bit of cr0, a control register, which apparently cannot be set directly
	or eax, 0x1
	mov cr0, eax

	jmp CODE_SEG:init_pm	; make a far jump (to a new segment) - forces CPU to flush its cache
	
; Includes (gdt defined in 16-bit, and 32-bit functions)
%include "../functions/gdt.asm"	; Include the externally-defined Global Descriptor Table (referenced in switch_pm function)

[bits 32]
;Initialize registers and the stack once in PM
init_pm:
	
	mov ax, DATA_SEG	; Old segments are meaningless in PM
	mov ds, ax			; Point all segment registers to data selector defined in GDT
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
		
	mov ebp, 0x90000	; Update stack position to be at top of free space
	mov esp, ebp

	;Protected Mode start
	
	call KERNEL_OFFSET
	
	jmp $

; Boot sector data
MSG_REAL_LOAD: db "Started in 16-bit Real Mode... ", 0
BOOT_DRIVE:	db 0
MSG_LOAD_KERNEL: db "Loading kernel into memory... ", 0

; Pad and boot sector indicator
times 510 - ($-$$) db 0
dw 0xaa55
