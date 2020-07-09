
readSector:
    ; 用int 13h 读取扇区内容到内存
    ; read al sectors from si to es:bx
    ; from sector si
    ; to   es:bx
    ; sector count al

     push ax
     push bx ;
     mov ax,si
     mov bl,18
     div bl
     ;磁头号
     mov dh,al
     and dh,0x01
     ;驱动器号
     mov dl,0
     ;柱面
     mov ch,al
     shr ch,1
     ;扇区
     mov cl,ah
     add cl,1
     ; es:bx存储位置
     pop bx
     ; 扇区数目
     pop ax ; al
     .reading:
        mov ah,2;读数据
        int 13h
        jc .reading
     ret

showNumber:
    ; 显示一个整数
    ; ax  the number to show
    push ax
    push bx
    push cx
    push dx
    mov cx,0
    mov bl,10 ;显示十进制数
    calcNumberLoop:
       div bl
       add cx,1
       movzx  dx,ah;
       push dx
       movzx ax,al
       cmp al,0
       jnz calcNumberLoop;
    showNumberLoop:
        pop dx
        mov al,dl
        add al,48;
        call showChar;
        loop showNumberLoop;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
showChar:
    ; 显示一个字符
    ; al 目标字符
    ; '\n' 换行
    push ax
    push di
    cmp al,10 ; 10 也即 \n
    jz showCharLine;
    mov di,[cursor]
    mov [es:di],al
    mov byte [es:di+1],0x02;// 绿色
    add di,2
    mov [cursor],di
    jmp showCharEnd;
    showCharLine:
    mov ax,[cursor]
    mov dl,160
    div dl
    xor ah,ah
    mul dl
    add ax,160
    mov [cursor],ax
    showCharEnd:
    pop di
    pop ax
    ret
showMessage:

    ; 显示一段字符串
    ;cx number of the string
    ;ds:si the start of the string
    ;
    ;
    push ax
    push es
    push si

    mov ax,0xb800
    mov es,ax

    cmp cx,0
    jz showMessageRet;
    showMessageLoop:
        mov al,[si]
        add si,1
        call showChar;
        loop showMessageLoop
    showMessageRet:
    pop si
    pop es
    pop ax
    ret