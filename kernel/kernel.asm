Code_Selector equ 8
extern cstart
extern gdt_ptr

section .tss
StackSpace resb 2*1024
StackTop:
section .text
global _start
_start:
    mov esp,StackTop
    sgdt [gdt_ptr]
    call cstart
    lgdt [gdt_ptr]

    jmp Code_Selector:csinit

csinit:
    push 0
    popfd
    hlt
