### Stack frames: local variables, pointers to locals, signed arithmetic
###
### A function that needs memory of its own reserves it on the stack:
###
###     push %rbp               # prologue
###     mov  %rsp, %rbp
###     sub  $N, %rsp           # N bytes of locals at -1(%rbp) ... -N(%rbp)
###     ...
###     leave                   # epilogue: mov %rbp, %rsp ; pop %rbp
###     ret
###
### Each call gets a fresh frame, so locals are private to that call.

.section .rodata
s_div:   .asciz " / "
s_eq:    .asciz " = "
s_rem:   .asciz ", remainder "
newline: .asciz "\n"

.section .text
.global _start

_start:
    mov $-17, %rdi
    mov $5, %rsi
    call show_divmod            # -17 / 5 = -3, remainder -2

    mov $100, %rdi
    mov $-7, %rsi
    call show_divmod            # 100 / -7 = -14, remainder 2

    mov $-9223372036854775808, %rdi
    mov $10, %rsi
    call show_divmod            # the most negative 64-bit number works too

    mov $60, %rax
    xor %rdi, %rdi
    syscall

# divmod(a = %rdi, b = %rsi, r = %rdx) -> %rax = a / b, and stores a % b at *r
#   Signed division: idiv divides the 128-bit value %rdx:%rax by its operand.
#   cqo fills %rdx with copies of the sign bit of %rax (sign extension).
divmod:
    mov %rdx, %r8               # save r: cqo and idiv overwrite %rdx
    mov %rdi, %rax
    cqo
    idiv %rsi                   # rax = quotient, rdx = remainder
    mov %rdx, (%r8)             # *r = remainder
    ret

# show_divmod(a = %rdi, b = %rsi): print "a / b = q, remainder r"
#
#   Frame layout:
#      8(%rbp)  return address
#      0(%rbp)  caller's %rbp      <- %rbp
#     -8(%rbp)  a
#    -16(%rbp)  b
#    -24(%rbp)  q
#    -32(%rbp)  r                  <- %rsp
show_divmod:
    push %rbp
    mov %rsp, %rbp
    sub $32, %rsp

    mov %rdi, -8(%rbp)          # every call below may destroy %rdi/%rsi,
    mov %rsi, -16(%rbp)         # so keep a and b in the frame

    lea -32(%rbp), %rdx         # 3rd argument: the ADDRESS of local r
    call divmod                 # a and b are still in %rdi, %rsi
    mov %rax, -24(%rbp)         # q

    mov -8(%rbp), %rdi
    call print_int
    lea s_div(%rip), %rdi
    call print_str
    mov -16(%rbp), %rdi
    call print_int
    lea s_eq(%rip), %rdi
    call print_str
    mov -24(%rbp), %rdi
    call print_int
    lea s_rem(%rip), %rdi
    call print_str
    mov -32(%rbp), %rdi         # divmod filled this in through the pointer
    call print_int
    lea newline(%rip), %rdi
    call print_str

    leave
    ret

# print_int(n = %rdi): print a signed integer in decimal
#   Uses a 32-byte buffer in its own stack frame instead of a .bss buffer.
#      -32(%rbp) ... -1(%rbp)  char buf[32]
print_int:
    push %rbp
    mov %rsp, %rbp
    sub $32, %rsp

    mov %rbp, %rsi              # one past the end of buf; fill right to left
    mov $10, %rcx
    mov %rdi, %rax
    test %rax, %rax
    jns .print_int_digits
    neg %rax                    # print |n| first, the '-' comes after
.print_int_digits:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .print_int_digits

    test %rdi, %rdi             # n is still in %rdi: was it negative?
    jns .print_int_write
    dec %rsi
    movb $'-', (%rsi)
.print_int_write:
    mov %rbp, %rdx
    sub %rsi, %rdx              # length = end - start
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
