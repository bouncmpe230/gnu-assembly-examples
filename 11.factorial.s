### Recursion: n! for n = 0 .. 20
###
### A recursive call is an ordinary call. Each call saves what it still needs
### (here: n) on the stack, so every level keeps its own copy:
###
###   fact(3): push 3, call fact(2)
###              fact(2): push 2, call fact(1)
###                         fact(1): base case, return 1
###              pop 2 -> return 2 * 1 = 2
###   pop 3 -> return 3 * 2 = 6
###
### 20! is the largest factorial that fits in 64 bits.

.section .data
s_fact:  .asciz "! = "
newline: .asciz "\n"

.section .bss
numbuf: .space 32

.section .text
.global _start

_start:
    xor %rbx, %rbx              # n = 0; %rbx is callee-saved, so the
                                # functions we call will not destroy it
.main_loop:
    mov %rbx, %rdi
    call print_uint             # n
    lea s_fact(%rip), %rdi
    call print_str              # "! = "
    mov %rbx, %rdi
    call fact
    mov %rax, %rdi
    call print_uint             # n!
    lea newline(%rip), %rdi
    call print_str

    inc %rbx
    cmp $20, %rbx
    jle .main_loop

    mov $60, %rax
    xor %rdi, %rdi
    syscall

# fact(n = %rdi) -> %rax = n!
#   fact(n) = 1                 if n <= 1
#   fact(n) = n * fact(n - 1)   otherwise
fact:
    cmp $1, %rdi
    jg .fact_recurse
    mov $1, %rax                # base case
    ret
.fact_recurse:
    push %rdi                   # save n: %rdi is caller-saved
    dec %rdi
    call fact                   # rax = fact(n - 1)
    pop %rdi                    # get our own n back
    imul %rdi, %rax             # rax = n * fact(n - 1)
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
