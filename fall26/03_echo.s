# 03_echo.s: read a line and print it (Fall 2026)
#   echo "hello" | ./03_echo   ->   hello
#
# New here: the read system call, and a subroutine (call / ret).

    .section .bss
buf:
    .space 256              # the longest line we accept. Any size works, as
                            #   long as read is told the same number below

    .section .text
    .global _start
_start:
    mov   $0, %rax          # system call 0 = read
    mov   $0, %rdi          # 0 = standard input
    lea   buf(%rip), %rsi   # where to store the bytes
    mov   $256, %rdx        # at most 256 bytes: the size of buf, so read
                            #   can never write past its end
    syscall                 # rax = bytes actually read, '\n' included

    mov   %rax, %rdx        # length: print exactly what was read
    lea   buf(%rip), %rsi   # address
    call  print
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall

# print: write rdx bytes starting at address rsi
# The caller puts the address and length straight into rsi and rdx, the
# registers write wants them in, so only rax and rdi are left to set.
# call pushes the address of the next instruction on the stack and jumps
# here; ret pops that address and jumps back.
print:
    mov   $1, %rax          # write
    mov   $1, %rdi          # standard output
    syscall
    ret
