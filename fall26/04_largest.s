# 04_largest.s: procedures that return two values (PS2 v2)
#   echo "17 4 250 9" | ./04_largest   ->   250
#
# parse_uint returns the number in rax and the position after it in rdx.
# The main loop keeps its own values in callee-saved registers
# (rbx, r12) so that they survive every call.

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

    lea   line(%rip), %r12  # p
    mov   $0, %rbx          # largest so far
next:
    mov   %r12, %rdi
    call  skip_spaces       # rax = p after spaces
    mov   %rax, %r12
    movzbq (%r12), %rax
    sub   $'0', %rax
    cmp   $9, %rax
    ja    done              # no more numbers
    mov   %r12, %rdi
    call  parse_uint        # rax = value, rdx = p
    mov   %rdx, %r12
    cmp   %rbx, %rax
    jbe   next
    mov   %rax, %rbx        # new largest
    jmp   next
done:
    mov   %rbx, %rdi
    call  print_uint
    mov   $60, %rax
    mov   $0, %rdi
    syscall

# skip_spaces(p): return in rax the first address at or after p (rdi)
# that does not hold a space.
skip_spaces:
    mov   %rdi, %rax
skip:
    cmpb  $' ', (%rax)
    jne   skipped
    inc   %rax
    jmp   skip
skipped:
    ret

# parse_uint(p): read the decimal number that starts at p (rdi).
# Returns the value in rax and the address of the first non-digit in rdx.
parse_uint:
    mov   $0, %rax          # value
    mov   %rdi, %rdx        # position
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

# print_uint(n): print n (rdi) in decimal and a newline (see 03_print_uint.s)
print_uint:
    push  %rbp
    mov   %rsp, %rbp
    sub   $32, %rsp
    mov   %rdi, %rax
    lea   -1(%rbp), %rsi
    movb  $'\n', (%rsi)
    mov   $10, %rcx
pdigit:
    mov   $0, %rdx
    div   %rcx
    add   $'0', %dl
    dec   %rsi
    mov   %dl, (%rsi)
    cmp   $0, %rax
    jne   pdigit
    mov   %rbp, %rdx
    sub   %rsi, %rdx
    mov   $1, %rax
    mov   $1, %rdi
    syscall
    mov %rbp, %rsp
    pop %rbp # leave
    ret
