BaseOfKernelFile   equ  0x8000 ; 内核文件被加载到的位置段地址
OffsetOfKernelFile equ  0      ; 内核文件被加载到的偏移位置
BaseOfKernelFilePhyAddr equ 0x80000
KernelEntryPointPhyAddr equ 0x30400
section .16
    org 0x90000  ;
    jmp start
    %include	"pm.inc"
    ; GDT
    ;                            段基址     段界限, 属性
    LABEL_GDT:	    Descriptor 0,            0, 0              ; 空描述符
    LABEL_DESC_FLAT_C:  Descriptor 0,      0fffffh, DA_CR|DA_32|DA_LIMIT_4K ;0-4G
    LABEL_DESC_FLAT_RW: Descriptor 0,      0fffffh, DA_DRW|DA_32|DA_LIMIT_4K;0-4G
    LABEL_DESC_VIDEO:   Descriptor 0B8000h, 0ffffh, DA_DRW|DA_DPL3 ; 显存首地址

    GdtLen		equ	$ - LABEL_GDT
    GdtPtr		dw	GdtLen - 1				; 段界限
    		    dd  LABEL_GDT		; 基地址

                db  "start of selector" ; use this to know the position gdt ptr
    ; GDT 选择子
    SelectorFlatC		equ	LABEL_DESC_FLAT_C	- LABEL_GDT
    SelectorFlatRW		equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
    SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT + SA_RPL3

start:
    mov ax,cs
    mov ds,ax

    mov si,msgWelcome
    mov cx,welcomeLen
    call showMessage
    ; 加载内核文件
    mov ax,BaseOfKernelFile
    mov es,ax
    mov bx,OffsetOfKernelFile
    mov al,10 ;读取10个扇区
    mov si,20 ;从第20个扇区读取
    ;加载内核
    call readSector
    mov si,msgKernelLoaded
    mov cx,kernelLoadedLen
    call showMessage
    jmp toProtectMode; 跳转到保护模式

toProtectMode:
    ; load global descriptor table
    lgdt [GdtPtr]
    ; close the interrupt
    cli
    ; open the a20
    in al,92h
    or al,00000010b
    out 92h,al
    ; change to protect mode
    mov eax,cr0
    or  eax,1
    mov cr0,eax

    jmp dword SelectorFlatC:Label_Pm_Start

msgWelcome:
    db "        Welcome to Loader ",0x0a
    db "       start to load kernel now        ",0x0a
    welcomeLen equ $-msgWelcome
msgKernelLoaded:
    db "     the kernel has been loaded now   ",0x0a
    kernelLoadedLen equ $-msgKernelLoaded

cursor:
    dw 480 ; the line 4


%include "util.asm"

; 进入32位模式
section .s32
bits 32
align 32
Label_Pm_Start:
    mov ax,SelectorVideo
    mov gs,ax
    mov ah,04h
    mov al,'P'
    mov [gs:((80*0+79)*2)],ax
    ; set up segment registers
    mov ax,SelectorFlatRW
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov ss,ax
    mov esp,TopOfStack
    call SetUpPaging
    ; show Page at the right-top corner
    mov ah,04h
    mov al,'P'
    mov [gs:((80*1+76)*2)],ax
    mov al,'a'
    mov [gs:((80*1+77)*2)],ax
    mov al,'g'
    mov [gs:((80*1+78)*2)],ax
    mov al,'e'
    mov [gs:((80*1+79)*2)],ax

    ;重置内核位置
    call InitKernel
    ; 进入内核
    jmp SelectorFlatC:KernelEntryPointPhyAddr


PageDirBase equ 0x100000 ; the base address of page directory
PageTblBase equ 0x101000 ; the base address of page table

; 建立分页机制
; 与实际内存一一对应
SetUpPaging:
    xor edx,edx
    mov eax,0x2000000 ; 我们的内存写死的32M
    mov ebx,0x400000;4096*1024一个也表对应4M的空间
    div ebx
    mov ecx,eax
    test edx,edx
    jz .no_remainder
    inc ecx
.no_remainder:
    push ecx
    mov  ax,SelectorFlatRW
    mov  es,ax
    mov  edi,PageDirBase
    xor  eax,eax
    mov  eax,PageTblBase | PG_P | PG_USU | PG_RWW
    ; 初始化页目录
.1:
    stosd  ;store eax at es:edi,edi=edi+4
    add eax,4096
    loop .1
    pop eax
    ; 初始化页表
    mov ebx,1024
    mul ebx
    mov ecx,eax
    mov edi,PageTblBase
    xor eax,eax
    mov eax,PG_P | PG_USU|PG_RWW
.2:
    stosd
    add eax,4096
    loop .2

    mov eax,PageDirBase
    mov cr3,eax
    mov eax,cr0
    or  eax,0x80000000
    mov cr0,eax
    jmp short .3
.3:
    nop
    ret

InitKernel:
    mov cx,[BaseOfKernelFilePhyAddr+0x2c]; header number ,e_phnum
    movzx ecx,cx
    mov esi,[BaseOfKernelFilePhyAddr+0x1c];offset of header, e_phoff
    add esi,BaseOfKernelFilePhyAddr       ;指向header开始处
    ;
    .Begin:
    mov eax,[esi+0]  ; 段类型为0的话不做处理
    cmp eax,0
    jz .NoAction
    push dword [esi+0x10]; 大小
    mov eax,[esi+0x4]    ; p_offset
    add eax,BaseOfKernelFilePhyAddr; source  address
    push eax; header address in memory
    push dword [esi+0x8] ; p_vaddr,destination address
    call MemoryCopy
    add esp,12
    .NoAction:
    add esi,0x20; add the size of header
    dec ecx
    jnz .Begin

    ret
; ------------------------------------------------------------------------
; 内存拷贝，仿 memcpy
; ------------------------------------------------------------------------
; void* MemCpy(void* es:pDest, void* ds:pSrc, int iSize);
MemoryCopy:
    push ebp
    mov  ebp,esp
    push edi
    push esi
    push ecx

    mov edi,[ebp+8]
    mov esi,[ebp+12]
    mov ecx,[ebp+16]
    .1:
        cmp ecx,0
        jz .2
        mov al,[ds:esi]
        mov [ds:edi],al
        dec ecx
        inc esi
        inc edi
        jmp .1
    .2:
    pop ecx
    pop esi
    pop edi
    pop ebp
    ret

section .data
align 32
StackSpace times 1024 db 0
TopOfStack equ $
times 1000 db 2
db "End"
