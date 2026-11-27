# 03_print_uint.s: a procedure with a local buffer on the stack (PS2 v2)
#   ./03_print_uint   ->   0, 42, 1984 and 18446744073709551615, one per line

    .section .text
    .global _start
_start:
    mov   $0, %rdi
    call  print_uint
    mov   $42, %rdi
    call  print_uint
    mov   $1984, %rdi
    call  print_uint
    mov   $-1, %rdi         # the largest unsigned 64-bit value
    call  print_uint

    mov   $60, %rax
    mov   $0, %rdi
    syscall

# print_uint(n): print n (rdi, unsigned) in decimal and a newline.
# Returns nothing. Changes only caller-saved registers.
print_uint:
    push  %rbp              # prologue
    mov   %rsp, %rbp
    sub   $32, %rsp         # -32(%rbp)..-1(%rbp)

    mov   %rdi, %rax        # n
    lea   -1(%rbp), %rsi    # last byte of buf
    movb  $'\n', (%rsi)
    mov   $10, %rcx
digit:
    mov   $0, %rdx
    div   %rcx              # rax = n/10, rdx = n%10
    add   $'0', %dl
    dec   %rsi
    mov   %dl, (%rsi)       # right to left
    cmp   $0, %rax
    jne   digit

    mov   %rbp, %rdx        # length
    sub   %rsi, %rdx
    mov   $1, %rax          # write
    mov   $1, %rdi
    syscall

    mov %rbp, %rsp
    pop %rbp                   # epilogue
    ret
