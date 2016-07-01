;PROTECTED MODE STRING PRINT

[bits 32]

;Constants
VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f

;Prints null-termed string pointed to by edx
print_string_pm:
	pusha
	mov edx, VIDEO_MEMORY	;set edx to the start of vid mem
	
	.loop:
		mov al, [ebx]			;Store the char at ebx in al
		mov ah, WHITE_ON_BLACK	;Store attributes in ah
		
		cmp al, 0				;if al == 0 end string
		je .done
		
		mov [edx], ax			;Store char and attributes at current char cell
		
		add ebx, 1				;inc edx to next char in string
		add edx, 2				;move to next char cell in vid mem
		
		jmp .loop
		
	.done:
		popa
		ret
