;UniversalOS Bootloader
org 7C00h
bits 16
section .text:
global _start
_start:
    cli
    cld
    xor ax, ax
    mov ds, ax ;DS = 0
    xor dh, dh
    mov bp, dx
    mov dx, 0x07E0
    mov ss, dx
    mov dx, 0x0150
    mov sp, dx
    cwd
    xor bx, bx
    mov cx, 0x0003 ;DISK Retry Counter
    mov ax, 0x0003 ;CGA Mode
    mov di, 0xB800 ;CGA mem
    mov es, di
    xor di, di
VIDEO:
    mov ah, 0x1F
    mov byte [attribute], ah
    push bp ;BP && DI to stack for safety w/OLD BIOS
    push di
    int 0x10 ;SET VIDEO
    pop di
    pop bp
    int 0x11 ;MDA??
    and al, 0x30
    cmp al, 0x30
    jne .call_print
    mov ax, 0x0007
    push bp
    push di
    int 0x10
    pop di
    pop bp
    mov di, 0xB000
    mov es, di
    xor di, di
    xchg ah, al ;Attribute on AH, AL = 0
    mov byte [attribute], ah
    
    .call_print:
        mov si, msg
        call PRINT
        add di, 116 ;LF && CR

DISK:
    clc
    push es
    mov bx, 0x0050
    mov es, bx
    xor bx, bx
    push cx
    mov cx, 0x0002
    mov ax, 0x0208
    mov dx, bp
    push di
    push bp
    int 0x13 ;CHS Read Sectors (8)
    pop bp ;BP, DI, to stack for safety w/OLD BIOS
    pop di
    pop cx ;Get updated retry counter
    pop es
    jc .check_if_deep_sleep
    jmp KERNEL

    .check_if_deep_sleep:
        xor ax, ax
        push di
        push bp
        int 0x13
        pop bp
        pop di
        loop DISK
        jc ERROR


KERNEL:
    mov si, kernel
    call PRINT
    mov ax, 0x0050
    push ax
    xor ax, ax
    push ax
    retf

ERROR:
    mov byte [error_code], ah
    mov si, error
    call PRINT ;printing error msg
    xor ah, ah
    mov ah, [error_code]
    db 0xD4, 0x10 ;AAM, 16d (Indocumented Opcode)
    mov cl, 0x01
    call PRINT_HEX
    hlt
PRINT_HEX:
    
    .hex_ascii_conversion:
        xchg al, ah
        add al, '0'
        cmp al, '9'
        jb .print_hex
        add al, 0x07

    .print_hex:
        push ax
        mov ah, [attribute]
        stosw
        pop ax
        loop .hex_ascii_conversion
        ret


PRINT:
    mov ah, [attribute] ;Load attribute on AH
    
    .print_string:
        lodsb
        test al, al
        jz .end_of_string
        stosw
        jmp .print_string
    
    .end_of_string:
        ret



section .data:

    ;Strings
    msg db "Booting UniversalOS...", 0
    kernel db "Done! :D", 0
    error db "CRITICAL DISK ERROR!!! Error Code: 0x", 0 

    ;Integers Variables
    error_code db 0x00
    attribute db 0x00

    ;Padding and boot sign
    times 510-($-$$) db 0
    dw 0x55AA