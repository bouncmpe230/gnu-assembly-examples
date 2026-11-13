### Assembly functions called from C (see 18.main.c)
###
### Build:  gcc -o 18.c_calls_asm 18.main.c 18.funcs.s
###
### The C compiler uses the same calling convention as 9.functions.s: for the
### C call sum_array(nums, n) it puts nums in %rdi and n in %rsi, and reads
### the result from %rax. Following the convention is all it takes for C and
### assembly to call each other.

.section .text
.global sum_array               # .global: visible to other object files
.global str_upper

# long sum_array(const long *a, long n)
#   a = %rdi, n = %rsi, result in %rax
sum_array:
    xor %rax, %rax              # sum = 0
    xor %rcx, %rcx              # i = 0
.sum_loop:
    cmp %rsi, %rcx
    jge .sum_done
    add (%rdi,%rcx,8), %rax     # sum += a[i]  (a long is 8 bytes)
    inc %rcx
    jmp .sum_loop
.sum_done:
    ret

# void str_upper(char *s)
#   s = %rdi, no return value; changes the caller's string in place
str_upper:
    movb (%rdi), %al
    test %al, %al
    jz .upper_done              # stop at the terminating 0
    cmp $'a', %al
    jb .upper_next
    cmp $'z', %al
    ja .upper_next
    sub $32, %al                # 'a' - 'A' = 32
    movb %al, (%rdi)
.upper_next:
    inc %rdi
    jmp str_upper
.upper_done:
    ret

.section .note.GNU-stack,"",@progbits
