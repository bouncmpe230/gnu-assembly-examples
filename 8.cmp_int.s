.section .data
num1: .quad 30
num2: .quad 42
msg:  .asciz "Max: "
newline: .asciz "\n"

.section .bss
outstr: .space 32

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
    mov %rax, %rdi              # 1st argument: the number
    lea outstr(%rip), %rsi      # 2nd argument: a 32-byte buffer
    call int_to_str             # returns rax = first digit, rdx = length

    mov %rax, %rsi              # write(1, first digit, length)
    mov $1, %rax
    mov $1, %rdi
    syscall

    mov $1, %rax
    mov $1, %rdi
    lea newline(%rip), %rsi
    mov $1, %rdx
    syscall

    mov $60, %rax
    xor %rdi, %rdi
    syscall

# int_to_str(n = %rdi, buf = %rsi)
#   Writes the decimal digits of n at the END of the 32-byte buffer buf.
#   Returns %rax = address of the first digit, %rdx = number of digits.
int_to_str:
    mov %rdi, %rax              # rax = n (div divides rdx:rax)
    lea 32(%rsi), %r8           # r8 = end of buffer
    mov %r8, %rsi               # rsi = write position, moves left
    mov $10, %rcx
.loop:
    xor %rdx, %rdx
    div %rcx                    # rax = rax / 10, rdx = rax % 10
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .loop
    mov %rsi, %rax              # return value: start of the digits
    mov %r8, %rdx
    sub %rsi, %rdx              # second return value: length
    ret
