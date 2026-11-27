# 02_clobber_fixed.s: the repair of 02_clobber.s (PS2 v2)
#   ./02_clobber_fixed   ->   *****
#
# The counter now lives in rbx, a callee-saved register: every function
# that changes rbx must restore it before returning. putc does not touch
# rbx, so the value is still there after the call.

    .section .text
    .global _start
_start:
    mov   $5, %rbx          # print 5 stars
again:
    mov   $'*', %rdi
    call  putc
    dec   %rbx              # survived the call
    jnz   again

    mov   $'\n', %rdi
    call  putc
    mov   $60, %rax
    mov   $0, %rdi
    syscall

# putc: print the character in dil
putc:
    push  %rdi              # char at (%rsp)
    mov   $1, %rax          # write(1, rsp, 1)
    mov   $1, %rdi
    mov   %rsp, %rsi
    mov   $1, %rdx
    syscall                 # sets rcx, r11
    pop   %rdi
    ret
