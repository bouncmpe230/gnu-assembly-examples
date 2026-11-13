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
    sub $'0', %rcx        # rcx = digit value if the byte is '0'..'9'
    cmp $9, %rcx          # unsigned: anything below '0' wraps to a huge value
    ja done1              # not a digit ('\n', 0, ...) -> number ends
    imul $10, %r8
    add %rcx, %r8
    inc %rsi
    jmp convert1
done1:

    ### Read second number
    ### (Typed input arrives one line per read. Piped input such as
    ###  printf '30\n42\n' | ./4.cmp_int can arrive in the FIRST read,
    ###  leaving buf2 empty -- then the second number is taken as 0.)
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
    sub $'0', %rcx        # rcx = digit value if the byte is '0'..'9'
    cmp $9, %rcx          # unsigned: anything below '0' wraps to a huge value
    ja done2              # not a digit ('\n', 0, ...) -> number ends
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
    mov %rax, %r10        # syscalls overwrite rax; keep the result in r10

    ### Print "Max: "
    mov $1, %rax
    mov $1, %rdi
    lea prompt(%rip), %rsi
    mov $5, %rdx
    syscall

    ### Convert r10 (bigger number) to string -> outstr
    mov %r10, %rax
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
    lea outstr+31(%rip), %rdx
    sub %rsi, %rdx        # length = end - start (number of digits)
    mov $1, %rax
    mov $1, %rdi
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
