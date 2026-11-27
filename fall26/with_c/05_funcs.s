# 05_funcs.s: assembly functions called from C (PS2 v2)
#   see 05_main.c
#
# Nothing here is special to C. A function that follows the calling
# convention can be called from C, and can call C.

    .section .text
    .global min_index       # .global: visible to other object files
    .global sum_map

# long min_index(const long *a, long n)
#   in:   rdi = a, rsi = n (n >= 1)
#   out:  rax = index of the smallest element; the first one on ties
#   changes: rax, rcx, rdx   (a leaf: it calls nothing, saves nothing)
min_index:
    mov   $0, %rax          # best = 0
    mov   $1, %rcx          # i = 1
min_loop:
    cmp   %rsi, %rcx
    jge   min_done          # i >= n
    mov   (%rdi,%rcx,8), %rdx
    cmp   (%rdi,%rax,8), %rdx
    jge   min_next          # a[i] >= a[best]: the earlier one stays
    mov   %rcx, %rax
min_next:
    inc   %rcx
    jmp   min_loop
min_done:
    ret

# long sum_map(const long *a, long n, long (*f)(long))
#   in:   rdi = a, rsi = n, rdx = address of a function
#   out:  rax = f(a[0]) + f(a[1]) + ... + f(a[n-1])
#
# The loop calls f, and f may change every caller-saved register. So a, n,
# f, i and the sum live in callee-saved registers, which sum_map must save
# first. Five pushes and the return address are 48 bytes: rsp is a multiple
# of 16 at the call, as C functions expect.
sum_map:
    push  %rbx
    push  %r12
    push  %r13
    push  %r14
    push  %r15
    mov   %rdi, %r12        # a
    mov   %rsi, %r13        # n
    mov   %rdx, %r14        # f
    mov   $0, %rbx          # i
    mov   $0, %r15          # sum
map_loop:
    cmp   %r13, %rbx
    jge   map_done
    mov   (%r12,%rbx,8), %rdi
    call  *%r14             # rax = f(a[i])
    add   %rax, %r15
    inc   %rbx
    jmp   map_loop
map_done:
    mov   %r15, %rax
    pop   %r15              # restore in reverse order
    pop   %r14
    pop   %r13
    pop   %r12
    pop   %rbx
    ret

    .section .note.GNU-stack,"",@progbits
