### Arrays of 64-bit integers: indexing with a scale factor, bubble sort
###
### Element i of a .quad array lives at  base + i * 8,  which is exactly the
### addressing mode  (%base, %index, 8).  a[i+1] is  8(%base, %index, 8).

.section .data
array:  .quad 42, -7, 19, 0, 3, 88, -15, 23, 5, 11
.equ N, (. - array) / 8         # element count, computed by the assembler

.section .rodata
s_before: .asciz "before: "
s_after:  .asciz "after:  "

.section .text
.global _start

_start:
    lea s_before(%rip), %rdi
    call print_str
    lea array(%rip), %rdi
    mov $N, %rsi
    call print_array

    lea array(%rip), %rdi
    mov $N, %rsi
    call bubble_sort

    lea s_after(%rip), %rdi
    call print_str
    lea array(%rip), %rdi
    mov $N, %rsi
    call print_array

    mov $60, %rax
    xor %rdi, %rdi
    syscall

# bubble_sort(a = %rdi, n = %rsi): sort n signed quads in place, ascending
#
#   for (i = n - 1; i > 0; i--)
#       for (j = 0; j < i; j++)
#           if (a[j] > a[j+1]) swap(a[j], a[j+1]);
#
#   A leaf function (calls nothing) that only uses caller-saved registers
#   has nothing to save or restore.
bubble_sort:
    mov %rsi, %rcx
    dec %rcx                    # i = n - 1
.outer:
    cmp $0, %rcx
    jle .sorted
    xor %rdx, %rdx              # j = 0
.inner:
    cmp %rcx, %rdx
    jge .next_pass
    mov (%rdi,%rdx,8), %rax     # rax = a[j]
    mov 8(%rdi,%rdx,8), %r8     # r8  = a[j+1]
    cmp %r8, %rax
    jle .no_swap                # signed: jle/jg, not jbe/ja (those are unsigned)
    mov %r8, (%rdi,%rdx,8)
    mov %rax, 8(%rdi,%rdx,8)
.no_swap:
    inc %rdx
    jmp .inner
.next_pass:
    dec %rcx
    jmp .outer
.sorted:
    ret

# print_array(a = %rdi, n = %rsi): print the elements separated by spaces
print_array:
    push %rbx
    push %r12
    push %r13
    mov %rdi, %rbx              # rbx = a
    mov %rsi, %r12              # r12 = n
    xor %r13, %r13              # r13 = i
.print_array_loop:
    cmp %r12, %r13
    jge .print_array_done
    mov (%rbx,%r13,8), %rdi     # a[i]
    call print_int
    mov $' ', %rdi
    call print_char
    inc %r13
    jmp .print_array_loop
.print_array_done:
    mov $'\n', %rdi
    call print_char
    pop %r13
    pop %r12
    pop %rbx
    ret

# print_char(c = %rdi): write one byte to stdout
#   The stack is ordinary memory: push c and write it straight from there.
print_char:
    push %rdi                   # low byte of %rdi is now at (%rsp)
    mov $1, %rax
    mov $1, %rdi
    mov %rsp, %rsi
    mov $1, %rdx
    syscall
    add $8, %rsp
    ret

# print_int(n = %rdi): print a signed integer (see 10.stack_frame.s)
print_int:
    push %rbp
    mov %rsp, %rbp
    sub $32, %rsp
    mov %rbp, %rsi
    mov $10, %rcx
    mov %rdi, %rax
    test %rax, %rax
    jns .print_int_digits
    neg %rax
.print_int_digits:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .print_int_digits
    test %rdi, %rdi
    jns .print_int_write
    dec %rsi
    movb $'-', (%rsi)
.print_int_write:
    mov %rbp, %rdx
    sub %rsi, %rdx
    mov $1, %rax
    mov $1, %rdi
    syscall
    leave
    ret

# strlen(s = %rdi) -> %rax
strlen:
    xor %rax, %rax
.strlen_loop:
    cmpb $0, (%rdi,%rax,1)
    je .strlen_done
    inc %rax
    jmp .strlen_loop
.strlen_done:
    ret

# print_str(s = %rdi): write a 0-terminated string to stdout
print_str:
    push %rbx
    mov %rdi, %rbx
    call strlen
    mov %rax, %rdx
    mov %rbx, %rsi
    mov $1, %rax
    mov $1, %rdi
    syscall
    pop %rbx
    ret
