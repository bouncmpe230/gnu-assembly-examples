# 02_digits.s: print the digits 0 to 9 (Fall 2026, the A86 example rewritten)
#   ./02_digits   ->   0123456789
#
# Plan: build the whole text in a buffer, then print it with ONE write
# (a system call per character would work, but is far slower).
#
# Registers:  rsi = address of buf      rcx = i, the loop counter

    .section .bss           # data with no initial value: starts as zeros
buf:                        #   and takes no room in the program file
    .space 11               # 10 digit characters + 1 byte for the '\n'

    .section .text
    .global _start
_start:
    lea   buf(%rip), %rsi
    mov   $0, %rcx          # i = 0
next:
    mov   %cl, %al          # cl = lowest byte of rcx. A character is one
                            #   byte, so we work with byte registers
    add   $'0', %al         # number -> character: '0' is 48, so 3 -> 51 = '3'
    mov   %al, (%rsi,%rcx)  # buf[i] = al        (address = rsi + rcx)
    inc   %rcx
    cmp   $10, %rcx
    jb    next              # while rcx < 10
    movb  $'\n', (%rsi,%rcx) # rcx is 10 now: buf[10] = '\n'. The b in movb
                            #   says "one byte"; with a register operand
                            #   (like al above) the size is already clear

    mov   $1, %rax          # write(1, buf, 11)
    mov   $1, %rdi
    mov   $11, %rdx         # length: 10 digits + '\n'. rsi still holds buf
    syscall

    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall
