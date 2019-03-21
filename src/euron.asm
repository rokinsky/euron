global euron
extern get_value, put_value

; &arr[i]
%define lookup(arr, i) ((arr) + (SCALE) * (i))

; ABI: until euron works,
; $rdi stores uint64_t n, $rsi - const char* prog,
; so save and revert are used when calling external function.
%macro save 0
    push    rdi
    push    rsi
%endmacro

%macro revert 0
    pop     rsi
    pop     rdi
%endmacro

; ABI: prologue and epilogue are used to save stack.
%macro prologue 0
    push    rbp
    mov     rbp, rsp
%endmacro

%macro epilogue 0
    mov     rsp, rbp
    pop     rbp
%endmacro

; It's used only to initialization spinlocks,
; for sequence N result is almost dq 0, ..., N - 1.
%macro sequence 1
%assign i 0
%rep    %1
    dq i
%assign i i+1
%endrep
%endmacro

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
NUL         equ 0                        ; '\0' or 0
SCALE       equ 8                        ; 8 bytes (64 bit)
CLOSED      equ -1                       ; max N

section .data
; Spinlock per euron, where i := owner, j := euron to sync.
; locks[i] has 3 states:
; 1. i      - opened only for i (to put in values[i] stack's top),
; 2. j      - opened only for j (to get values[i]),
; 3. CLOSED - acquired by someone (i or j).
align 8
locks:      sequence N                   ; 1st state initially.

section .bss
; Protected data, values[i] holds i's value to exchange with j.
values:     resq N

section .text
; uint64_t euron(uint64_t n, char const *prog);
euron:
    prologue
    jmp     execute

.return:
    pop     rax                          ; Calculation result.
    epilogue
    ret

execute:                                 ; INVARIANT! $rdi := n, $rsi := *prog
    cmp     byte [rsi], NUL
    jz      euron.return
    mov     rcx, ZERO
    jmp     try_digit

.next:
    inc     rsi
    jmp     execute

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
    jmp     execute.next

.muliply:
    pop     rax
    pop     rdx
    mul     rdx
    push    rax
    jmp     execute.next

.negation:
    pop     rax
    neg     rax
    push    rax
    jmp     execute.next

.digit:
    sub     rcx, ZERO
    push    rcx
    jmp     execute.next

.number:
    push    rdi
    jmp     execute.next

.branch:
    pop     rax
    cmp     QWORD [rsp], NUL
    je      execute.next
    add     rsi, rax
    jmp     execute.next

.clean:
    pop     rax
    jmp     execute.next

.duplicate:
    mov     rax, [rsp]
    push    rax
    jmp     execute.next

.exchange:
    pop     rax
    pop     rdx
    push    rax
    push    rdx
    jmp     execute.next

.get:
    save
    call    get_value                    ; $rax := get_value(n)
    revert
    push    rax
    jmp     execute.next

.put:
    pop     rdx
    save
    mov     rsi, rdx                     ; w := pop()
    call    put_value                    ; put_value(n, w)
    revert
    jmp     execute.next

; REMINDER: i := n (owner, $rdi), j := euron to sync.
.synchronize:
    ; non-critical section
    mov     rdx, rsi                     ; saving *prog
    pop     rcx                          ; holds j for 1st post-protocol
    ; pre-protocol
    mov     rsi, rdi                     ; $rsi := i
    call    acquire                      ; acquire(i, i)
    ; critical section
    pop     qword [lookup(values, rdi)]  ; values[i] := pop()
    ; post-protocol
    mov     rsi, rcx                     ; $rsi := j
    call    release                      ; release(i, j)

    ; pre-protocol
    xchg    rsi, rdi                     ; $rdi := j, $rsi := i
    call    acquire                      ; acquire(j, i)
    ; critical section
    push    qword [lookup(values, rdi)]  ; push(values[j])
    ; post-protocol
    push    rsi                          ; saving i / n
    mov     rsi, rdi                     ; $rsi := j
    call    release                      ; release(j, j)
    ; non-critical section
    pop     rdi                          ; reverting i / n
    mov     rsi, rdx                     ; reverting *prog
    jmp     execute.next

; void acquire(uint64_t spinlock, uint64_t expected);
acquire:
    lea     r8, [lookup(locks, rdi)]     ; address of locks[spinlock]
    mov     r9, CLOSED                   ; desired

align 8
.loop:
    mov     rax, rsi                     ; expected
    lock \
    cmpxchg [r8], r9
    jne     .loop

    ret

; void release(uint64_t spinlock, uint64_t desired);
release:
    mov     [lookup(locks, rdi)], rsi    ; locks[spinlock] := desired
    ret
