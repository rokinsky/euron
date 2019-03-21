; TODO macro for foo(N) return 0, ..., N - 1

section .rodata
SUM         equ '+'
MULTIPLY    equ '*'
NEGATION    equ '-'
ZERO        equ '0'
NINE        equ '9'
NUMBER      equ 'n'
BRANCH      equ 'B'
CLEAN       equ 'C'
DUPLICATE   equ 'D'
EXCHANGE    equ 'E'
GET         equ 'G'
PUT         equ 'P'
SYNCHRONIZE equ 'S'
NUL         equ 0
SCALE       equ 8                        ; 8 bytes (64 bit)
CLOSED      equ -1                       ; for spinlocks', (-1 % 2^64) == max N

section .data
align 8
locks:      dq 0, 1 ; TODO foo(N)
values:     times N dq -1

section .text
    global  euron
    extern  get_value, put_value

; uint64_t euron(uint64_t n, char const *prog);
euron:
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
    push    rsi                          ; saving char* prog
    push    rdi                          ; saving uint64_t n
    call    get_value                    ; $rax := get_value(n)
    pop     rdi                          ; revering uint64_t n
    pop     rsi                          ; reverting char* prog
    push    rax
    jmp     sequence.inc

.put:
    pop     rax
    push    rsi                          ; saving char* prog
    push    rdi                          ; saving uint64_t n
    mov     rsi, rax                     ; w := pop()
    call    put_value                    ; put_value(n, w)
    pop     rdi                          ; revering uint64_t n
    pop     rsi                          ; reverting char* prog
    jmp     sequence.inc

.synchronize:                            ; $rdi := i
    mov     rdx, rsi                     ; saving char* prog

    mov     rsi, rdi                     ; $rsi := $rdi
    call    acquire                      ; acquire(i, i)

    pop     rsi                          ; $rsi := j
    pop     qword [values + SCALE * rdi] ; values[i] := pop()

    call    release                      ; release(i, j)

    xchg    rsi, rdi                     ; $rdi := j, $rsi := i
    call    acquire                      ; acquire(j, i)

    push    qword [values + SCALE * rdi] ; push(values[j])

    push    rsi                          ; saving i (uint64_t n)
    mov     rsi, rdi                     ; $rdi := j, $rsi := j
    call    release                      ; release(j, j)

    pop     rdi                          ; reverting i (uint64_t n)
    mov     rsi, rdx                     ; reverting char* prog

    jmp     sequence.inc

; void acquire(uint64_t spinlock, uint64_t expected);
acquire:
    lea     r9, [locks + SCALE * rdi]    ; address of locks[spinlock]
    mov     r8, CLOSED                   ; try to close spinlock
.loop:
    mov     rax, rsi                     ; expected value
    lock \
    cmpxchg [r9], r8
    jne     .loop
    ret

; void release(uint64_t spinlock, uint64_t opened);
release:
    mov     [locks + SCALE * rdi], rsi   ; locks[spinlock] := opened
    ret
