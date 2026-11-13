### Bitwise operations and shifts; assembler macros
###
###   and / or / xor / not    bit by bit
###   shl                     shift left  (x << k == x * 2^k)
###   shr                     logical shift right:    fills with 0
###   sar                     arithmetic shift right: fills with the sign bit
###                           (x >> k == x / 2^k, rounded down, also for x < 0)
###   test a, b               computes a AND b only to set the flags
###                           (test is to and what cmp is to sub)

.section .rodata
s_a:   .asciz "a           = "
s_b:   .asciz "b           = "
s_and: .asciz "a AND b     = "
s_or:  .asciz "a OR  b     = "
s_xor: .asciz "a XOR b     = "
s_not: .asciz "NOT a       = "
s_shl: .asciz "a SHL 2     = "
s_shr: .asciz "a SHR 2     = "
s_pop: .asciz "popcount(a) = "
s_sar: .asciz "-8 SAR 1    = "
s_lsr: .asciz "-8 SHR 1    = "
newline: .asciz "\n"

### A macro is expanded by the assembler as if its body were typed in place.
### \label and \value are replaced by the arguments.
.macro show_bits label, value
    lea \label(%rip), %rdi
    call print_str
    mov \value, %rdi
    mov $8, %rsi                # print the low 8 bits
    call print_bits
    lea newline(%rip), %rdi
    call print_str
.endm

.macro show_int label, value
    lea \label(%rip), %rdi
    call print_str
    mov \value, %rdi
    call print_int
    lea newline(%rip), %rdi
    call print_str
.endm

.section .text
.global _start

_start:
    mov $0b00101101, %rbx       # a = 45 (GAS accepts binary 0b... literals)
    mov $0b00011011, %r12       # b = 27
    show_bits s_a, %rbx
    show_bits s_b, %r12

    mov %rbx, %r13
    and %r12, %r13              # 1 where both are 1
    show_bits s_and, %r13

    mov %rbx, %r13
    or %r12, %r13               # 1 where at least one is 1
    show_bits s_or, %r13

    mov %rbx, %r13
    xor %r12, %r13              # 1 where they differ
    show_bits s_xor, %r13

    mov %rbx, %r13
    not %r13                    # flip every bit
    show_bits s_not, %r13

    mov %rbx, %r13
    shl $2, %r13                # a * 4
    show_bits s_shl, %r13

    mov %rbx, %r13
    shr $2, %r13                # a / 4
    show_bits s_shr, %r13

    mov %rbx, %rdi
    call popcount
    mov %rax, %r13              # the macro calls print_str, which clobbers %rax
    show_int s_pop, %r13

    mov $-8, %r13
    sar $1, %r13                # sign bit copied in: -4
    show_int s_sar, %r13

    mov $-8, %r13
    shr $1, %r13                # 0 shifted in: a huge positive number
    show_int s_lsr, %r13

    mov $60, %rax
    xor %rdi, %rdi
    syscall

# popcount(x = %rdi) -> %rax: number of 1 bits in x
#   x & (x - 1) clears the lowest 1 bit, so loop until x becomes 0.
popcount:
    xor %rax, %rax
.popcount_loop:
    test %rdi, %rdi
    jz .popcount_done
    lea -1(%rdi), %rdx          # rdx = x - 1
    and %rdx, %rdi              # x = x & (x - 1)
    inc %rax
    jmp .popcount_loop
.popcount_done:
    ret

# print_bits(x = %rdi, width = %rsi): print the low `width` bits of x,
# most significant first. 1 <= width <= 64.
print_bits:
    push %rbp
    mov %rsp, %rbp
    sub $64, %rsp               # char buf[64] at (%rsp)
    mov %rsp, %r8               # r8 = next free byte in buf
    mov %rsi, %rcx              # rcx = bit number
.print_bits_loop:
    dec %rcx                    # width-1, ..., 1, 0
    mov %rdi, %rax
    shr %cl, %rax               # bring bit rcx down to bit 0
                                # (a variable shift count must be in %cl)
    and $1, %rax                # keep only that bit
    add $'0', %al
    mov %al, (%r8)
    inc %r8
    test %rcx, %rcx
    jnz .print_bits_loop

    mov %r8, %rdx
    sub %rsp, %rdx              # length = width
    mov %rsp, %rsi
    mov $1, %rax
    mov $1, %rdi
    syscall
    leave
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
