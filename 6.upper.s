.section .data
msg: .asciz "hello"
len: .quad 5

.section .text
.global _start

_start:
    lea msg(%rip), %rsi
    xor %rcx, %rcx

.loop:
    movb (%rsi,%rcx,1), %al
    cmp $'a', %al
    jb .next
    cmp $'z', %al
    ja .next
    sub $32, %al
    movb %al, (%rsi,%rcx,1)

.next:
    inc %rcx
    cmp len(%rip), %rcx
    jne .loop

    mov $1, %rax
    mov $1, %rdi
    lea msg(%rip), %rsi
    mov len(%rip), %rdx
    syscall

    mov $60, %rax
    xor %rdi, %rdi
    syscall