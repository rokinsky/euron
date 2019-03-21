; TODO macro foo(N) : 0, ..., N - 1

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
SCALE       equ 8   ; 8 bytes (64 bit)
CLOSED      equ -1  ; used for spinlock, (-1 mod 2^64) = (2^64) - 1 = max N

;SYS_WRITE   equ 1
;STDOUT      equ 1
    
section .data
locks:      dq 0, 1
values:     times N dq -1

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

align 8
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

align 8
.inc:
    inc     rsi
    jmp     sequence

align 8
try_digit:
    cmp     rcx, NINE
    jg      operations

    cmp     byte [rsi], cl
    je      operations.digit
    inc     rcx
    jmp     try_digit

align 8
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
    pop     rcx                                 ; $rdi := i, $rcx := j

    ; TODO void acquire(uint64_t spinlock, uint64_t expected);
    ; TODO void release(uint64_t spinlock, uint64_t opened);

    ; acquire(i, i)
    lea     r9, [locks + SCALE * rdi]           ; locks[i]
    mov     r8, CLOSED                          ; value of closed spinlock
.spinlock1_acquire:
    mov     rax, rdi                            ; expected value (`i`)
    lock \
    cmpxchg [r9], r8
    jne     .spinlock1_acquire
                                                ; here is a critical section
    pop     qword [values + SCALE * rdi]        ; value to exchange in values[i]

    ; release(i, j)
.spinlock1_release:
    mov     [locks + SCALE * rdi], rcx          ; made open for `j`

    ; acquire(j, i)
    lea     r9, [locks + SCALE * rcx]
    mov     r8, CLOSED
.spinlock2_acquire:
    mov     rax, rdi
    lock \
    cmpxchg [r9], r8
    jne     .spinlock2_acquire

    push    qword [values + SCALE * rcx]

    ; release(j, j)
.spinlock2_release:
    mov     [locks + SCALE * rcx], rcx

    jmp     sequence.inc