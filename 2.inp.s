.section .bss
buffer: .space 32

.section .text
.global _start

_start:
    mov $0, %rax
    mov $0, %rdi
    lea buffer(%rip), %rsi
    mov $32, %rdx
    syscall

    mov $1, %rax
    mov $1, %rdi
    lea buffer(%rip), %rsi
    mov $32, %rdx
    syscall

    mov $60, %rax
    xor %rdi, %rdi
    syscall