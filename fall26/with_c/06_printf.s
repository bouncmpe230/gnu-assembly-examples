# 06_printf.s: assembly calls C (PS2 v2)
#   ./06_asm_calls_c   ->   3 orders, last served at 10
#
# Built with gcc, which links the C library and supplies _start. The C
# start-up code calls main, so main is an ordinary function: it returns
# with ret, and its return value is the exit status.
#
# Not allowed in the project (no C library there). It is here to show the
# convention from the caller's side.

    .section .rodata
fmt:
    .asciz "%ld orders, last served at %ld\n"

    .section .text
    .global main
main:
    sub   $8, %rsp          # return address 8 + 8 = 16: aligned for the call

    lea   fmt(%rip), %rdi   # argument 1: the format
    mov   $3, %rsi          # argument 2
    mov   $10, %rdx         # argument 3
    mov   $0, %eax          # printf takes a variable number of arguments:
                            #   al = how many are floating point (none)
    call  printf@PLT

    add   $8, %rsp
    mov   $0, %eax          # return 0
    ret

    .section .note.GNU-stack,"",@progbits
