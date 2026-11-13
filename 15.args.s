### Command-line arguments
###
### When _start begins, the kernel has put argc and argv on the stack:
###
###     (%rsp)          argc
###    8(%rsp)          argv[0]   pointer to the program name
###   16(%rsp)          argv[1]   pointer to the first argument
###    ...
###    8*argc+8(%rsp)   NULL      end of argv (environment pointers follow)
###
### Try:  ./15.args hello "two words" 42

.section .data
s_argc:  .asciz "argc = "
s_argv:  .asciz "argv["
s_close: .asciz "] = "
newline: .asciz "\n"

.section .bss
numbuf: .space 32

.section .text
.global _start

_start:
    mov (%rsp), %r12            # r12 = argc
    lea 8(%rsp), %r13           # r13 = argv: address of the pointer array

    lea s_argc(%rip), %rdi
    call print_str
    mov %r12, %rdi
    call print_uint
    lea newline(%rip), %rdi
    call print_str

    xor %rbx, %rbx              # i = 0
.args_loop:
    cmp %r12, %rbx
    jge .args_done
    lea s_argv(%rip), %rdi
    call print_str
    mov %rbx, %rdi
    call print_uint
    lea s_close(%rip), %rdi
    call print_str
    mov (%r13,%rbx,8), %rdi     # argv[i] is a pointer to a 0-terminated string
    call print_str
    lea newline(%rip), %rdi
    call print_str
    inc %rbx
    jmp .args_loop
.args_done:

    mov $60, %rax
    xor %rdi, %rdi
    syscall

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

# print_uint(n = %rdi): print an unsigned integer in decimal
print_uint:
    mov %rdi, %rax
    lea numbuf+32(%rip), %rsi
    mov $10, %rcx
.print_uint_loop:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .print_uint_loop
    lea numbuf+32(%rip), %rdx
    sub %rsi, %rdx
    mov $1, %rax
    mov $1, %rdi
    syscall
    ret
