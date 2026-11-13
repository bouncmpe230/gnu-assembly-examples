.section .bss
buffer: .space 32

.section .text
.global _start

_start:
    mov $0, %rax
    mov $0, %rdi
    lea buffer(%rip), %rsi
    mov $32, %rdx
    syscall                 # rax = number of bytes actually read

    mov %rax, %rdx          # write back only what was read (not all 32 bytes)
    mov $1, %rax
    mov $1, %rdi
    lea buffer(%rip), %rsi
    syscall

    mov $60, %rax
    xor %rdi, %rdi
    syscall
