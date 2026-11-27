# ex3_gcd.s: solution to Exercise 3 (PS2 v2)
#   echo "84 36 60" | ./ex3_gcd   ->   12
#
# Print the greatest common divisor of the numbers on the line (at least
# one number, each at least 1, separated by single spaces).
#
# Euclid's algorithm for two numbers:
#     while b != 0:   (a, b) = (b, a mod b)
#     the answer is a
# For more than two numbers: g = first; then g = gcd(g, x) for every x.
#
# Concepts: an algorithm as a procedure with a contract, div and its
# remainder, calling a procedure in a loop, callee-saved registers.
#
# Registers in the main loop (callee-saved, they live across the calls):
#   rbx = g, the gcd so far      r12 = position in the input

    .equ  MAXLINE, 256

    .section .bss
line:
    .space MAXLINE+1

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall

    lea   line(%rip), %rdi
    call  parse_uint        # the first number
    mov   %rax, %rbx        # g
    mov   %rdx, %r12
more:
    cmpb  $' ', (%r12)
    jne   done              # '\n': no more numbers
    lea   1(%r12), %rdi     # skip the space
    call  parse_uint        # rax = x
    mov   %rdx, %r12
    mov   %rbx, %rdi
    mov   %rax, %rsi
    call  gcd               # g = gcd(g, x)
    mov   %rax, %rbx
    jmp   more
done:
    mov   %rbx, %rdi
    call  print_uint
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall

# gcd(a, b): greatest common divisor, by Euclid's algorithm
#   in:       rdi = a, rsi = b
#   out:      rax = gcd(a, b); gcd(a, 0) = a
#   changes:  rax, rdx, rsi
gcd:
    mov   %rdi, %rax        # a
gcd_loop:
    cmp   $0, %rsi
    je    gcd_done          # b == 0: the answer is a
    mov   $0, %rdx
    div   %rsi              # rdx = a mod b
    mov   %rsi, %rax        # a = b
    mov   %rdx, %rsi        # b = a mod b
    jmp   gcd_loop
gcd_done:
    ret

# parse_uint(p): read the decimal number that starts at p
#   in:       rdi = address of the first digit
#   out:      rax = value, rdx = address of the first non-digit
#   changes:  rax, rcx, rdx
parse_uint:
    mov   $0, %rax
    mov   %rdi, %rdx
parse:
    movzbq (%rdx), %rcx
    sub   $'0', %rcx
    cmp   $9, %rcx
    ja    parsed
    imul  $10, %rax
    add   %rcx, %rax
    inc   %rdx
    jmp   parse
parsed:
    ret

# print_uint(n): print n (rdi) in decimal and a newline
#   changes:  rax, rcx, rdx, rsi, rdi, r11
print_uint:
    push  %rbp
    mov   %rsp, %rbp
    sub   $32, %rsp         # local buffer: -32(%rbp)..-1(%rbp)
    mov   %rdi, %rax
    lea   -1(%rbp), %rsi
    movb  $'\n', (%rsi)
    mov   $10, %rcx
pdigit:
    mov   $0, %rdx
    div   %rcx
    add   $'0', %dl
    dec   %rsi
    mov   %dl, (%rsi)       # digits right to left
    cmp   $0, %rax
    jne   pdigit
    mov   %rbp, %rdx        # length
    sub   %rsi, %rdx
    mov   $1, %rax          # write
    mov   $1, %rdi
    syscall
    leave
    ret
