;	GDT
gdt_start:

gdt_null:		;Mandatory null descriptor
	dd 0x0		;dd = define double word (4 bytes) - GDT requires 8 bytes of null to start
	dd 0x0
	
gdt_code:		;Code segment descriptor
	; [Base 31:24][G][D/B][L][AVL][Seg limit 19:16][P][DPL 14:13][S][Type 11:8][Base 23:16] - 16 bits
	; [Base 16:31] [Seg limit 0:15]
	
	;Base - Segment base address (split up) - 32 bits
	;G - granularity - if set, multiplies limit by 16*16*16, so 0xffff becomes 0x ffff000
	;D/B - Default operation size (0 = 16 bit, 1 = 32)
	;L - 64-bit code segment
	;AVL - Available for use by system software - not necessary
	;Segment limit - split up - 20 bits - defines segment size
	;P - segment present - used for virtual memory - 1 means segment is present in memory
	;DPL - Descriptor privelege level - 00 is highest priv level
	;S - Descriptor type (0 = system, 1 = code or data)
	;TYPE - segment type
	;	Code: 1 for code
	;	Conforming: 0 not conforming--code from lower priv cannot call this segment (protected)
	;	Readable: 1 if readable, 0 if execute only; readable allows reading of constants defined in code
	;	Accessed: Used for debugging and virtual memory techniques--CPU sets bit when it accesses the segment

	;base = 0x0, limit = 0xfffff
	;1st flags: (present)1 (privelege)00 (descriptor)1 -> 1001b
	;type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
	;2nd flags: (granularity)1 (32 bit default)1 (64-bit seg)0 (AVL)0 -> 1100b
	
	dw 0xffff		;	limit (bits 0-15)
	dw 0x0			;	base (bits 0-15)
	db 0x0			;	base (bits 16-23)
	db 10011010b	;	1st flags, type flags
	db 11001111b	;	2nd flags, limit (bits 16-19)
	db 0x0			;	base (bits 24-31)
	
gdt_data:	;the data segment descriptor
	;Same as code segment except for type flags:
	;Type flags: (code)0 (expand_down)0 (writable)1 (accessed)0 -> 0010b
	
	dw 0xffff		;limit (bits 0-15)
	dw 0x0			;base (bits 0-15)
	db 0x0			;base (bits 16-23)
	db 10010010b	;1st flags, type flags
	db 11001111b	;2nd flags, limit(bits 16-19)
	db 0x0			;base (bits 24-31)
	
gdt_end:	;The reason for putting a label at the end of the GDT is so we can have the assembler calc the size of the GDT for the GDT descriptor below

;	GDT DESCRIPTOR
gdt_descriptor:
	dw gdt_end - gdt_start - 1	;Size of GDT always less one of true size
	dd gdt_start				;Start address of our GDT
	
	;Define constants for the GDT segment descriptor offsets
	;segment registers must contain these in protected mode
	;e.g. when we set DS = 0x10 in PM, CPU knows that we mean it to use
	;the segment described at offset 0x10 (16 bites) in our GDT
	;which in our case is the data segment (0x0 -> NULL; 0x08 -> CODE; 0x10 -> DATA)
	
	CODE_SEG equ gdt_code - gdt_start
	DATA_SEG equ gdt_data - gdt_start