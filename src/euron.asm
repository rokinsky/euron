global euron
extern get_value, put_value

section .rodata
    _SUM    db '+' ; 43
    _MUL    db '*' ; 42
    _NEG    db '-' ; 61
    _ZERO   db '0' ; 48
    _NINE   db '9' ; 57
    _NUM    db 'n' ; 110
    _BRCH   db 'B' ; 66
    _CLN    db 'C' ; 67
    _DUP    db 'D' ; 68
    _EXCH   db 'E' ; 69
    _GET    db 'G' ; 71
    _PUT    db 'P' ; 80
    _SNCH   db 'S' ; 83

    SYS_WRITE equ 1
    SYS_EXIT  equ 60
    STDOUT    equ 1

section .text

euron:          ; "n(rdi), prog(rsi)"
    push rbp
    mov rbp, rsp
    mov rdx, rdi
    mov rdi, rsi
    call len

    mov rsp, rbp
    pop rbp
    ret

len:          ; "prog(rdi)"
    xor rcx, rcx
    not rcx
    sub al, al
    cld
    repne scasb
    not rcx
    lea rax, [rcx - 1]
    ret