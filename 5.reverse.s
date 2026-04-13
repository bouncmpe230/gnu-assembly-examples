.section .data
msg: .asciz "assembly"
len: .quad 8

.section .bss
revmsg: .space 8

.section .text
.global _start

_start:
    lea msg(%rip), %rsi
    lea revmsg(%rip), %rdi
    mov len(%rip), %rcx
    dec %rcx

.loop:
    mov (%rsi,%rcx,1), %al
    mov %al, (%rdi)
    inc %rdi
    dec %rcx
    jns .loop

    mov $1, %rax
    mov $1, %rdi
    lea revmsg(%rip), %rsi
    mov len(%rip), %rdx
    syscall

    mov $60, %rax
    xor %rdi, %rdi
    syscall