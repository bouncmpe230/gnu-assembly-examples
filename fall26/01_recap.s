# 01_recap.s: the recap in one program (PS2 v2)
#   ./01_recap   ->   max = 9
#
# Find the largest of five numbers and print it (one digit).
#
# Registers:  rbx = &nums[0]    rcx = i    rax = largest so far

    .equ  N, 5              # a constant: a name for 5, no memory

    .section .data          # variables with initial values
nums:
    .quad 4, 9, 2, 7, 5     # five numbers of 8 bytes each
msg:
    .ascii "max = ?\n"      # eight bytes; the '?' is replaced
    .equ  MSGLEN, 8         

    .section .bss           # variables that start as zero
best:
    .space 8                # room for one 8-byte number

    .section .text          # instructions
    .global _start
_start:
    lea   nums(%rip), %rbx  # rbx = address of nums
    mov   (%rbx), %rax      # largest so far = nums[0]
    mov   $1, %rcx          # i = 1
loop:
    cmp   $N, %rcx
    jae   done              # i >= N: all numbers seen
    cmp   %rax, (%rbx,%rcx,8) # compare nums[i] with the largest
    jbe   next              # not larger: keep the old one
    mov   (%rbx,%rcx,8), %rax # nums[i] is at rbx + 8*i
next:
    inc   %rcx
    jmp   loop
done:
    mov   %rax, best(%rip)  # store into the variable best
    add   $'0', %al         # the number 9 becomes the character '9'
    mov   %al, msg+6(%rip)  # overwrite the '?' (byte 6 of msg)

    mov   $1, %rax          # write(1, msg, MSGLEN)
    mov   $1, %rdi
    lea   msg(%rip), %rsi
    mov   $MSGLEN, %rdx
    syscall

    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall
