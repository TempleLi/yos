    org 0x7c00
    mov ax,cs
    mov ds,ax

    ; show start booting
    mov cx,message2-message1
    mov si,message1
    call showMessage
    ; 利用int 13h中断从软盘中读取数据
    mov ax,0x9000
    mov es,ax
    mov bx,0
    xor ax,ax
    mov al,10 ; 读取10个扇区
    mov si,10 ; 从第一个扇区开始读取
    call readSector


    mov cx,cursor-message2
    mov si,message2
    call showMessage
    jmp 0x9000:0

    %include "util.asm"
message1:
    db "start booting:",0x0a
message2:
    db "load loader complete",0x0a
cursor:
    dw 0
times 510-($-$$) db 0
db  0x55,0xaa