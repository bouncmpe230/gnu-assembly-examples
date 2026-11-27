# ex2_stats.s: solution to Exercise 2 (PS2 v2)
#   echo "12 7 300 45" | ./ex2_stats   ->   min=7 max=300 sum=364
#
# Read the numbers on one line (separated by single spaces, at least one)
# and print the smallest, the largest and the sum.
#
# Concepts: variables in .data (text) and .bss (numbers), reading and
# updating a variable in memory, three procedures with contracts, and a
# result that is passed on from one call to the next.
#
# Variables:  lo, hi, total   the three answers, 8 bytes each
# Registers:  r12 = position in the input (callee-saved: it lives
#                   across the calls to parse_uint)

    .equ  MAXLINE, 256

    .section .data
s_min:
    .asciz "min="           # .asciz: the characters and a 0 byte
s_max:
    .asciz " max="
s_sum:
    .asciz " sum="

    .section .bss
line:
    .space MAXLINE+1
lo:
    .space 8
hi:
    .space 8
total:
    .space 8
out:
    .space 128

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall

    # ---- the first number starts all three variables --------------
    lea   line(%rip), %rdi
    call  parse_uint        # rax = value, rdx = position after it
    mov   %rdx, %r12
    mov   %rax, lo(%rip)
    mov   %rax, hi(%rip)
    mov   %rax, total(%rip)

    # ---- every other number updates them --------------------------
more:
    cmpb  $' ', (%r12)
    jne   report            # '\n': no more numbers
    lea   1(%r12), %rdi     # skip the space
    call  parse_uint
    mov   %rdx, %r12
    add   %rax, total(%rip) # total += x
    cmp   lo(%rip), %rax
    jae   not_lower
    mov   %rax, lo(%rip)    # x < lo
not_lower:
    cmp   hi(%rip), %rax
    jbe   more
    mov   %rax, hi(%rip)    # x > hi
    jmp   more

    # ---- build "min=.. max=.. sum=..\n" in out --------------------
    # Every append returns the next free position in rax, which is
    # handed to the next append as its destination.
report:
    lea   s_min(%rip), %rdi
    lea   out(%rip), %rsi
    call  append_str
    mov   lo(%rip), %rdi
    mov   %rax, %rsi
    call  append_uint

    lea   s_max(%rip), %rdi
    mov   %rax, %rsi
    call  append_str
    mov   hi(%rip), %rdi
    mov   %rax, %rsi
    call  append_uint

    lea   s_sum(%rip), %rdi
    mov   %rax, %rsi
    call  append_str
    mov   total(%rip), %rdi
    mov   %rax, %rsi
    call  append_uint

    movb  $'\n', (%rax)
    inc   %rax
    lea   out(%rip), %rsi   # write(1, out, rax - out)
    mov   %rax, %rdx
    sub   %rsi, %rdx
    mov   $1, %rax
    mov   $1, %rdi
    syscall
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall

# append_str(src, dest): copy the text at src, up to its 0 byte, to dest
#   in:       rdi = address of the text, rsi = address to write to
#   out:      rax = address after the last character written
#   changes:  rax, rcx, rdi
append_str:
    mov   %rsi, %rax
as_loop:
    mov   (%rdi), %cl
    cmp   $0, %cl
    je    as_done           # the 0 byte is not copied
    mov   %cl, (%rax)
    inc   %rdi
    inc   %rax
    jmp   as_loop
as_done:
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
    ja    parsed            # not a digit
    imul  $10, %rax
    add   %rcx, %rax
    inc   %rdx
    jmp   parse
parsed:
    ret

# append_uint(n, dest): write n in decimal at dest
#   in:       rdi = n, rsi = address to write to
#   out:      rax = address after the last digit
#   changes:  rax, rcx, rdx, rsi, r8, r9
append_uint:
    push  %rbp
    mov   %rsp, %rbp
    sub   $32, %rsp         # local buffer: -32(%rbp)..-1(%rbp)
    mov   %rdi, %rax
    lea   -1(%rbp), %r8     # last byte of the buffer
    mov   %r8, %r9
    mov   $10, %rcx
split:
    mov   $0, %rdx
    div   %rcx              # rax = n/10, rdx = n%10
    add   $'0', %dl
    mov   %dl, (%r9)        # digits right to left
    dec   %r9
    cmp   $0, %rax
    jne   split
copy:
    inc   %r9
    mov   (%r9), %al        # then copied left to right
    mov   %al, (%rsi)
    inc   %rsi
    cmp   %r8, %r9
    jne   copy
    mov   %rsi, %rax
    leave
    ret
