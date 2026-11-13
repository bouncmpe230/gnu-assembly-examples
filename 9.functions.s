### Functions and the System V AMD64 calling convention (Linux, macOS, BSD)
###
###   arguments     : %rdi, %rsi, %rdx, %rcx, %r8, %r9, then on the stack
###   return value  : %rax
###   caller-saved  : %rax %rcx %rdx %rsi %rdi %r8-%r11
###                   -> a call may change them; save them yourself if needed
###   callee-saved  : %rbx %rbp %r12-%r15
###                   -> a function that uses them must restore them first
###   alignment     : %rsp must be a multiple of 16 right before every call
###
### `call f` pushes the return address and jumps to f; `ret` pops it back.

.section .data
s_max:    .asciz "max(30, 42) = "
s_strlen: .asciz "strlen(\"assembly\") = "
s_sum7:   .asciz "sum7(1, 2, 3, 4, 5, 6, 7) = "
word:     .asciz "assembly"
newline:  .asciz "\n"

.section .bss
numbuf: .space 32

.section .text
.global _start

_start:
    ### max(30, 42)
    lea s_max(%rip), %rdi
    call print_str
    mov $30, %rdi               # 1st argument
    mov $42, %rsi               # 2nd argument
    call max                    # result comes back in %rax
    mov %rax, %rdi
    call print_uint
    lea newline(%rip), %rdi
    call print_str

    ### strlen("assembly")
    lea s_strlen(%rip), %rdi
    call print_str
    lea word(%rip), %rdi
    call strlen
    mov %rax, %rdi
    call print_uint
    lea newline(%rip), %rdi
    call print_str

    ### sum7(1, ..., 7): only six arguments fit in registers
    lea s_sum7(%rip), %rdi
    call print_str
    mov $1, %rdi
    mov $2, %rsi
    mov $3, %rdx
    mov $4, %rcx
    mov $5, %r8
    mov $6, %r9
    sub $8, %rsp                # padding, so %rsp is 16-byte aligned at the call
    push $7                     # 7th argument goes on the stack
    call sum7
    add $16, %rsp               # the caller removes its stack arguments
    mov %rax, %rdi
    call print_uint
    lea newline(%rip), %rdi
    call print_str

    mov $60, %rax
    xor %rdi, %rdi
    syscall

# max(a = %rdi, b = %rsi) -> %rax
max:
    mov %rdi, %rax
    cmp %rsi, %rax
    jge .max_done
    mov %rsi, %rax
.max_done:
    ret

# sum7(a, b, c, d, e, f, g) -> %rax
#   a..f arrive in registers. g is on the stack, above the return address:
#      (%rsp)   return address (pushed by call)
#     8(%rsp)   g
sum7:
    mov %rdi, %rax
    add %rsi, %rax
    add %rdx, %rax
    add %rcx, %rax
    add %r8, %rax
    add %r9, %rax
    add 8(%rsp), %rax
    ret

# strlen(s = %rdi) -> %rax: number of bytes before the terminating 0
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
#   s is needed after the call to strlen, but %rdi is caller-saved, so we keep
#   it in %rbx. %rbx is callee-saved: we must give the caller its value back.
print_str:
    push %rbx                   # save the caller's %rbx
    mov %rdi, %rbx
    call strlen                 # rax = strlen(s)
    mov %rax, %rdx              # write(1, s, strlen(s))
    mov %rbx, %rsi
    mov $1, %rax
    mov $1, %rdi
    syscall
    pop %rbx                    # restore the caller's %rbx
    ret

# print_uint(n = %rdi): print an unsigned integer in decimal
print_uint:
    mov %rdi, %rax
    lea numbuf+32(%rip), %rsi   # fill the buffer from the end
    mov $10, %rcx
.print_uint_loop:
    xor %rdx, %rdx
    div %rcx                    # rax = rax / 10, rdx = rax % 10
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .print_uint_loop
    lea numbuf+32(%rip), %rdx
    sub %rsi, %rdx              # length = end - start
    mov $1, %rax
    mov $1, %rdi
    syscall
    ret
