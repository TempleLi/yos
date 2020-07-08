section .text
global _start
_start:
    mov ah,0x4
    mov al,'K'
    mov [gs:((80*2+79)*2)],ax
    jmp $
section .data:
    db "Hello,Wecelcom to the world CYS"
