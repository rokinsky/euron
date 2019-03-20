section .rodata
    SUM         equ '+' ; 43
    MULTIPLY    equ '*' ; 42
    NEGATION    equ '-' ; 61
    ZERO        equ '0' ; 48
    NINE        equ '9' ; 57
    NUMBER      equ 'n' ; 110
    BRANCH      equ 'B' ; 66
    CLEAN       equ 'C' ; 67
    DUPLICATE   equ 'D' ; 68
    EXCHANGE    equ 'E' ; 69
    GET         equ 'G' ; 71
    PUT         equ 'P' ; 80
    SYNCHRONIZE equ 'S' ; 83
    NUL         equ 0
    SCALE       equ 8
    
    ;SYS_WRITE   equ 1
    ;STDOUT      equ 1
    
section .data
    locks       times N * N dq -1
    values      times N dq -1

section .text
    global  euron
    extern  get_value, put_value

euron:          ; "n(rdi), prog(rsi)"
    push    rbp
    mov     rbp, rsp
    jmp     sequence

.return:
    pop     rax
    mov     rsp, rbp
    pop     rbp
    ret

sequence:
    cmp     byte [rsi], NUL
    jz      euron.return
    ;mov     r8, rdi
    ;mov     r9, rsi
    ;mov     rax, SYS_WRITE
    ;mov     rdi, STDOUT
    ;mov     rdx, 1
    ;syscall
    ;mov     rdi, r8
    ;mov     rsi, r9
    mov     rcx, ZERO
    jmp     try_digit

.inc:
    inc     rsi
    jmp     sequence

try_digit:
    cmp     rcx, NINE
    jg      operations

    cmp     byte [rsi], cl
    je      operations.digit
    inc     rcx
    jmp     try_digit

operations:
    cmp     byte [rsi], SUM
    je      .sum

    cmp     byte [rsi], MULTIPLY
    je      .muliply

    cmp     byte [rsi], NEGATION
    je      .negation

    cmp     byte [rsi], NUMBER
    je      .number

    cmp     byte [rsi], BRANCH
    je      .branch

    cmp     byte [rsi], CLEAN
    je      .clean

    cmp     byte [rsi], DUPLICATE
    je      .duplicate

    cmp     byte [rsi], EXCHANGE
    je      .exchange

    cmp     byte [rsi], GET
    je      .get

    cmp     byte [rsi], PUT
    je      .put

    cmp     byte [rsi], SYNCHRONIZE
    je      .synchronize

.sum:
    pop     rax
    pop     rdx
    add     rax, rdx
    push    rax
    jmp     sequence.inc

.muliply:
    pop     rax
    pop     rdx
    mul     rdx
    push    rax
    jmp     sequence.inc

.negation:
    pop     rax
    neg     rax
    push    rax
    jmp     sequence.inc

.digit:
    sub     rcx, ZERO
    push    rcx
    jmp     sequence.inc

.number:
    push    rdi
    jmp     sequence.inc

.branch:
    pop     rcx
    cmp     QWORD [rsp], NUL
    je      sequence.inc
    add     rsi, rcx
    ;test    r8, r8
    ;jg      .loop
    jmp     sequence.inc

.clean:
    pop     rax
    jmp     sequence.inc

.duplicate:
    mov     rax, [rsp]
    push    rax
    jmp     sequence.inc

.exchange:
    pop     rax
    pop     rdx
    push    rax
    push    rdx
    jmp     sequence.inc

.get:
    push    rsi
    push    rdi
    call    get_value
    pop     rdi
    pop     rsi
    push    rax
    jmp     sequence.inc

.put:
    pop     rax
    push    rsi
    push    rdi
    mov     rsi, rax
    call    put_value
    pop     rdi
    pop     rsi
    jmp     sequence.inc

.synchronize:
    pop     rcx
    pop     qword [values + SCALE * rdi]

    ; find my lock [$rdi][$rcx]
    mov     rax, rdi
    imul    rax, N
    add     rax, rcx
    ; spinlock.release (locks[$rdi][$rcx] := $rcx)
    lea     rax, [locks + SCALE * rax]
    mov     qword [rax], rcx

    ; find partner's spin lock [$rcx][$rdi]
    mov     rdx, rcx
    imul    rdx, N
    add     rdx, rdi
    lea     rdx, [locks + SCALE * rdx]

    mov     r8, 1
.busy_wait:
    ; spinlock.acquire (wait for locks[$rcx][$rdi] == $rdi)
    mov     rax, rdi
    lock \
    cmpxchg [rdx], r8
    jne     .busy_wait
    mov     r9, -1
    xchg    qword [values + SCALE * rcx], r9
    push    r9

    jmp     sequence.inc