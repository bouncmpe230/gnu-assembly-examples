# ex1_caesar.s: solution to Exercise 1 (PS2 v2)
#   echo "Hello, World! xyz" | ./ex1_caesar   ->   Khoor, Zruog! abc
#
# Caesar cipher: replace every letter by the letter SHIFT places later in
# the alphabet, wrapping around from z to a. Upper case stays upper case.
# Every other character is left as it is.
#
# Concepts: a constant, a reserved buffer, a byte loop with an index,
# unsigned range checks, arithmetic on character codes, changing memory
# in place. No procedures yet.
#
# Registers:  rbx = &line[0]    rcx = i    r12 = number of bytes read
#             al  = the character          dl = 'a' or 'A'

    .equ  MAXLINE, 256
    .equ  SHIFT, 3          # change this line to change the cipher

    .section .bss
line:
    .space MAXLINE

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall
    mov   %rax, %r12        # n = bytes read, the newline included

    lea   line(%rip), %rbx
    mov   $0, %rcx          # i = 0
next:
    cmp   %r12, %rcx
    jae   print             # i >= n: done
    mov   (%rbx,%rcx), %al  # c = line[i]

    mov   $'a', %dl         # is c in 'a'..'z'?
    cmp   $'a', %al
    jb    try_upper
    cmp   $'z', %al
    jbe   rotate
    jmp   skip              # above 'z': not a letter
try_upper:
    mov   $'A', %dl         # is c in 'A'..'Z'?
    cmp   $'A', %al
    jb    skip
    cmp   $'Z', %al
    ja    skip
rotate:
    sub   %dl, %al          # 0..25: the place in the alphabet
    add   $SHIFT, %al
    cmp   $26, %al
    jb    in_range
    sub   $26, %al          # past z: wrap around
in_range:
    add   %dl, %al          # back to a character code
    mov   %al, (%rbx,%rcx)  # line[i] = c
skip:
    inc   %rcx
    jmp   next

print:
    mov   $1, %rax          # write(1, line, n)
    mov   $1, %rdi
    lea   line(%rip), %rsi
    mov   %r12, %rdx
    syscall
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall
