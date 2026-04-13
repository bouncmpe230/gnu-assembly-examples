.section .data
msg:
    .asciz "Hello, world!\n"

.section .text
.global _start

_start:
    mov     $1, %rax            # syscall number for write
    mov     $1, %rdi            # file descriptor (stdout)
    lea     msg(%rip), %rsi     # address of message
    mov     $14, %rdx           # message length
    syscall

    mov     $60, %rax           # syscall number for exit
    xor     %rdi, %rdi          # exit code 0
    syscall
