.section .data
num1: .quad 30
num2: .quad 42
msg:  .asciz "Max: "
newline: .asciz "\n"

.section .bss
outstr: .space 16

.section .text
.global _start

_start:
    mov $1, %rax
    mov $1, %rdi
    lea msg(%rip), %rsi
    mov $5, %rdx
    syscall

    mov num1(%rip), %rax
    mov num2(%rip), %rbx
    cmp %rbx, %rax
    jge use_rax
    mov %rbx, %rax

use_rax:
    mov %rax, %rsi
    lea outstr(%rip), %rdi
    call int_to_str

    mov $1, %rax
    mov $1, %rdi
    lea outstr(%rip), %rsi
    mov $16, %rdx
    syscall

    mov $60, %rax
    xor %rdi, %rdi
    syscall

int_to_str:
    mov $10, %rcx
    lea outstr+15(%rip), %rdi
    movb $0, (%rdi)
    dec %rdi
.loop:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    mov %dl, (%rdi)
    dec %rdi
    test %rax, %rax
    jnz .loop
    lea 1(%rdi), %rsi
    ret