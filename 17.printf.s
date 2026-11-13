### Calling C library functions (printf, scanf, puts) from assembly
###
### Build with gcc instead of as + ld, so the C library gets linked in:
###     gcc -o 17.printf 17.printf.s
###
### With the C library we write `main`, not `_start`: the C runtime's own
### _start calls main and then exit(main's return value). Return from main
### (do not use the exit syscall): exit() is what flushes printf's buffer.
###
### Rules that matter when calling C:
###   - %rsp must be 16-byte aligned at the call (C code may rely on it)
###   - for variadic functions (printf, scanf) %al = number of vector
###     registers used for arguments; 0 here because we pass no floats
###   - `call printf@PLT` goes through the procedure linkage table, which
###     works for position-independent executables (gcc's default)

.section .rodata
prompt:  .asciz "Enter two integers: "
in_fmt:  .asciz "%ld %ld"
sum_fmt: .asciz "%ld + %ld = %ld\n"
mul_fmt: .asciz "%ld * %ld = %ld\n"
bad_msg: .asciz "invalid input"

.section .text
.global main

# int main(void)
#   -8(%rbp)  long a
#  -16(%rbp)  long b
main:
    push %rbp                   # on entry %rsp is 8 off from 16-alignment,
    mov %rsp, %rbp              # the push fixes that
    sub $16, %rsp

    ### printf(prompt)
    lea prompt(%rip), %rdi
    xor %eax, %eax
    call printf@PLT

    ### if (scanf("%ld %ld", &a, &b) != 2) goto bad_input
    lea in_fmt(%rip), %rdi
    lea -8(%rbp), %rsi          # &a
    lea -16(%rbp), %rdx         # &b
    xor %eax, %eax
    call scanf@PLT
    cmp $2, %eax                # scanf returns an int: the low half, %eax
    jne .bad_input

    ### printf("%ld + %ld = %ld\n", a, b, a + b)
    lea sum_fmt(%rip), %rdi
    mov -8(%rbp), %rsi
    mov -16(%rbp), %rdx
    lea (%rsi,%rdx), %rcx       # lea as a 3-operand add: rcx = rsi + rdx
    xor %eax, %eax
    call printf@PLT

    ### printf("%ld * %ld = %ld\n", a, b, a * b)
    lea mul_fmt(%rip), %rdi
    mov -8(%rbp), %rsi
    mov -16(%rbp), %rdx
    mov %rsi, %rcx
    imul %rdx, %rcx
    xor %eax, %eax
    call printf@PLT

    xor %eax, %eax              # return 0
    leave
    ret

.bad_input:
    lea bad_msg(%rip), %rdi
    call puts@PLT               # not variadic: no need to set %al
    mov $1, %eax                # return 1
    leave
    ret

# Tells the linker this code does not need an executable stack
# (without it, newer versions of ld print a warning).
.section .note.GNU-stack,"",@progbits
