# 02_clobber.s: a register that does not survive a call (PS2 v2)
#   ./02_clobber | head -c 40     prints far more than five stars
#
# The loop counter is in rcx. putc makes a system call, and syscall
# overwrites rcx (and r11). Under the calling convention rcx is
# caller-saved anyway: no function promises to keep it.
# See 02_clobber_fixed.s for the repair.

    .section .text
    .global _start
_start:
    mov   $5, %rcx          # print 5 stars
again:
    mov   $'*', %rdi
    call  putc
    dec   %rcx              # counter lost
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
