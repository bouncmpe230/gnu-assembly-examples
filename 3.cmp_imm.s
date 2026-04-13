.section .bss
outstr: .space 32        # Buffer for output string

.section .text
.global _start

_start:
    ### Print "Max: "
    mov $1, %rax
    mov $1, %rdi
    lea msg(%rip), %rsi
    mov $5, %rdx
    syscall

    ### Two immediate integers
    mov $30, %rax         # first number
    mov $42, %rbx         # second number

    cmp %rbx, %rax
    jge use_rax
    mov %rbx, %rax

use_rax:
    ### Convert RAX to string manually
    mov $10, %rcx
    lea outstr+31(%rip), %rdi
    movb $0, (%rdi)
    dec %rdi

.convert_loop:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    mov %dl, (%rdi)
    dec %rdi
    test %rax, %rax
    jnz .convert_loop

    lea 1(%rdi), %rsi     # start of string
    mov $1, %rax
    mov $1, %rdi
    mov $32, %rdx
    syscall

    ### Print newline
    mov $1, %rax
    mov $1, %rdi
    lea newline(%rip), %rsi
    mov $1, %rdx
    syscall

    ### Exit
    mov $60, %rax
    xor %rdi, %rdi
    syscall

### Inline strings (still in .text section)
msg:     .asciz "Max: "
newline: .asciz "\n"