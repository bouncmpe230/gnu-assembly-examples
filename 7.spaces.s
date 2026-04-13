.section .data
msg:    .asciz "a b c d e"
text:   .asciz "Spaces: "

.section .bss
count:  .space 1

.section .text
.global _start

_start:
    lea msg(%rip), %rsi         # %rsi = address of message
    xor %rcx, %rcx              # loop index
    xor %rbx, %rbx              # space counter in %bl

.loop:
    movzbq (%rsi,%rcx,1), %rax  # load next byte from string
    test %al, %al
    je .done                    # stop on null terminator
    cmp $' ', %al
    jne .next
    inc %bl

.next:
    inc %rcx
    jmp .loop

.done:
    add $'0', %bl
    mov %bl, count(%rip)

    # print "Spaces: "
    mov $1, %rax
    mov $1, %rdi
    lea text(%rip), %rsi
    mov $8, %rdx
    syscall

    # print count character
    mov $1, %rax
    mov $1, %rdi
    lea count(%rip), %rsi
    mov $1, %rdx
    syscall

    mov $60, %rax
    xor %rdi, %rdi
    syscall
