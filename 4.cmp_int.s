.section .bss
buf1:   .space 32        # input buffer for first number
buf2:   .space 32        # input buffer for second number
outstr: .space 32        # output buffer for converted integer

.section .text
.global _start

_start:
    ### Read first number
    mov $0, %rax          # syscall: read
    mov $0, %rdi          # stdin
    lea buf1(%rip), %rsi  # buffer
    mov $32, %rdx         # max bytes
    syscall

    ### Convert first input (buf1) to integer -> r8
    xor %r8, %r8
    lea buf1(%rip), %rsi
convert1:
    movzbq (%rsi), %rcx
    cmp $10, %rcx         
    je done1
    sub $'0', %rcx
    imul $10, %r8
    add %rcx, %r8
    inc %rsi
    jmp convert1
done1:

    ### Read second number
    mov $0, %rax
    mov $0, %rdi
    lea buf2(%rip), %rsi
    mov $32, %rdx
    syscall

    ### Convert second input (buf2) to integer -> r9
    xor %r9, %r9
    lea buf2(%rip), %rsi
convert2:
    movzbq (%rsi), %rcx
    cmp $10, %rcx
    je done2
    sub $'0', %rcx
    imul $10, %r9
    add %rcx, %r9
    inc %rsi
    jmp convert2
done2:

    ### Compare r8 and r9
    mov %r8, %rax
    cmp %r9, %rax
    jge use_r8
    mov %r9, %rax

use_r8:
    ### Convert rax (bigger number) to string -> outstr
    mov $10, %rcx
    lea outstr+31(%rip), %rdi
    movb $0, (%rdi)
    dec %rdi

convloop:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    mov %dl, (%rdi)
    dec %rdi
    test %rax, %rax
    jnz convloop

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

### Inline strings
prompt: .asciz "Max: "
newline: .asciz "\n"
