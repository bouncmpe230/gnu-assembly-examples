### Recursion with two recursive calls: fib(0) .. fib(20)
###
###   fib(0) = 0, fib(1) = 1
###   fib(n) = fib(n - 1) + fib(n - 2)
###
### Between the two calls we must remember n (to compute n - 2) and the result
### of fib(n - 1). Both have to survive a call, so they go into callee-saved
### registers -- which means fib must first save the caller's values of them.
###
### Each fib(n) makes about 1.6^n calls; try fib(40) to feel it.

.section .data
s_fib:   .asciz "fib(0..20):"
space:   .asciz " "
newline: .asciz "\n"

.section .bss
numbuf: .space 32

.section .text
.global _start

_start:
    lea s_fib(%rip), %rdi
    call print_str

    xor %rbx, %rbx              # n = 0
.main_loop:
    lea space(%rip), %rdi
    call print_str
    mov %rbx, %rdi
    call fib
    mov %rax, %rdi
    call print_uint
    inc %rbx
    cmp $20, %rbx
    jle .main_loop

    lea newline(%rip), %rdi
    call print_str

    mov $60, %rax
    xor %rdi, %rdi
    syscall

# fib(n = %rdi) -> %rax
fib:
    cmp $1, %rdi
    jg .fib_recurse
    mov %rdi, %rax              # base case: fib(0) = 0, fib(1) = 1
    ret
.fib_recurse:
    push %rbx                   # we are going to use %rbx and %r12,
    push %r12                   # so save the caller's values first
    sub $8, %rsp                # 8 + 2*8 + 8 = 32: keeps %rsp 16-byte aligned

    mov %rdi, %rbx              # rbx = n
    lea -1(%rbx), %rdi
    call fib                    # rax = fib(n - 1)
    mov %rax, %r12              # r12 = fib(n - 1)
    lea -2(%rbx), %rdi
    call fib                    # rax = fib(n - 2)
    add %r12, %rax              # rax = fib(n - 1) + fib(n - 2)

    add $8, %rsp
    pop %r12                    # restore in reverse order
    pop %rbx
    ret

# strlen(s = %rdi) -> %rax
strlen:
    xor %rax, %rax
.strlen_loop:
    cmpb $0, (%rdi,%rax,1)
    je .strlen_done
    inc %rax
    jmp .strlen_loop
.strlen_done:
    ret

# print_str(s = %rdi): write a 0-terminated string to stdout
print_str:
    push %rbx
    mov %rdi, %rbx
    call strlen
    mov %rax, %rdx
    mov %rbx, %rsi
    mov $1, %rax
    mov $1, %rdi
    syscall
    pop %rbx
    ret

# print_uint(n = %rdi): print an unsigned integer in decimal
print_uint:
    mov %rdi, %rax
    lea numbuf+32(%rip), %rsi
    mov $10, %rcx
.print_uint_loop:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .print_uint_loop
    lea numbuf+32(%rip), %rdx
    sub %rsi, %rdx
    mov $1, %rax
    mov $1, %rdi
    syscall
    ret
