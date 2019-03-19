section .rodata
    _SUM    equ '+' ; 43
    _MUL    equ '*' ; 42
    _NEG    equ '-' ; 61
    _ZERO   equ '0' ; 48
    _NINE   equ '9' ; 57
    _NUM    equ 'n' ; 110
    _BRCH   equ 'B' ; 66
    _CLN    equ 'C' ; 67
    _DUP    equ 'D' ; 68
    _EXCH   equ 'E' ; 69
    _GET    equ 'G' ; 71
    _PUT    equ 'P' ; 80
    _SNCH   equ 'S' ; 83

    SYS_WRITE equ 1
    STDOUT    equ 1
    NUL       equ 0

section .text
    global euron
    extern get_value, put_value

euron:          ; "n(rdi), prog(rsi)"
    push    rbp
    mov     rbp, rsp

.loop:
    ;mov     r8, rdi
    ;mov     r9, rsi
    ;mov     rsi, N
    cmp     byte [rsi], NUL
    jz      .exit
    ;mov     rax, SYS_WRITE
    ;mov     rdi, STDOUT
    ;mov     rdx, 1
    ;syscall
    ;mov     rdi, r8
    ;mov     rsi, r9

    mov     r8, _ZERO
.try_digit:
    cmp     r8, _NINE
    jg      .operations

    cmp     byte [rsi], r8b
    je      .digit
    inc     r8
    jmp     .try_digit

.operations:
    cmp     byte [rsi], _SUM
    je      .sum

    cmp     byte [rsi], _MUL
    je      .muliply

    cmp     byte [rsi], _NEG
    je      .negation

    cmp     byte [rsi], _NUM
    je      .number

    cmp     byte [rsi], _BRCH
    je      .branch

    cmp     byte [rsi], _CLN
    je      .clean

    cmp     byte [rsi], _DUP
    je      .duplicate

    cmp     byte [rsi], _EXCH
    je      .exchange

    cmp     byte [rsi], _GET
    je      .get

    cmp     byte [rsi], _PUT
    je      .put

    cmp     byte [rsi], _SNCH
    je      .synchronize

.inc:
    inc     rsi
    jmp     .loop

.sum:
    pop     r8
    pop     r9
    add     r8, r9
    push    r8
    jmp     .inc

.muliply:
    pop     r8
    pop     r9
    imul    r8, r9
    push    r8
    jmp     .inc

.negation:
    pop     rcx
    neg     rcx
    push    rcx
    jmp     .inc

.digit:
    sub     r8, _ZERO
    push    r8
    jmp     .inc

.number:
    push    rdi
    jmp     .inc

.branch:
    pop     r8
    cmp     QWORD [rsp], 0
    je      .inc
    add     rsi, r8
    ;test    r8, r8
    ;jg      .loop
    jmp     .inc

.clean:
    pop     r8
    jmp     .inc

.duplicate:
    mov     r8, [rsp]
    push    r8
    jmp     .inc

.exchange:
    pop     r8
    pop     r9
    push    r8
    push    r9
    jmp     .inc

.get:
    push    rsi
    push    rdi
    call    get_value
    pop     rdi
    pop     rsi
    push    rax
    jmp     .inc


.put:
    pop     r8
    push    rsi
    push    rdi
    mov     rsi, r8
    call    put_value
    pop     rdi
    pop     rsi
    jmp     .inc

.synchronize:
    jmp     .inc

.exit:
    pop     rax
    mov     rsp, rbp
    pop     rbp

    ret