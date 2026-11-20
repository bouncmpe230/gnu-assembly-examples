# ex1_reverse.s: solution to Fall 2026 Exercise 1
#   echo "5 12 300 7" | ./ex1_reverse   ->   7 300 12 5
#
# Read up to 32 numbers from one line into an array, then print them
# in reverse order, separated by single spaces.
#
# Skills: reserving space for an array, storing and loading with a
#         scaled index, string -> integer, integer -> string.
#
# Registers:  rsi = p, the position in the line   rbx = address of nums
#             r12 = n, how many numbers           rcx = value being read
#             rdi = next free byte of out (second half)
# append_uint leaves rbx and r12 alone, so they survive the call.

    .equ  MAXLINE, 256
    .equ  MAXN, 32

    .section .bss
line:
    .space MAXLINE+1        # read fills at most MAXLINE bytes, so the extra
                            #   byte stays 0 (.bss starts as zeros). The
                            #   scan below stops there if nothing else
                            #   stopped it earlier
nums:
    .space MAXN*8           # room for 32 numbers of 8 bytes
out:
    # A 64-bit number has at most 20 digits, and each number is followed
    # by one space: 21 bytes per number. The +1 is for the final '\n'.
    .space MAXN*21+1        # 20 digits and a space per number

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall

    # ---- read the numbers into nums[0..n-1] -----------------------
    lea   line(%rip), %rsi  # p
    lea   nums(%rip), %rbx
    mov   $0, %r12          # n
token:                      # find the start of the next number
    cmpb  $' ', (%rsi)
    jne   not_space
    inc   %rsi              # skip one space
    jmp   token
not_space:
    # Digit test with one unsigned compare: '0'..'9' become 0..9 after
    # c - '0'; anything else ('\n', the 0 byte) becomes a number above 9.
    movzbq (%rsi), %rax
    sub   $'0', %rax
    cmp   $9, %rax
    ja    stored_all        # no more numbers
    mov   $0, %rcx          # value
digit:                      # value = value * 10 + digit
    movzbq (%rsi), %rax
    sub   $'0', %rax
    cmp   $9, %rax
    ja    number_end        # not a digit: the number is complete
    imul  $10, %rcx
    add   %rax, %rcx
    inc   %rsi
    jmp   digit
number_end:
    mov   %rcx, (%rbx,%r12,8)   # nums[n] = value  (address = rbx + n*8)
    inc   %r12
    jmp   token

    # ---- print nums[n-1], ..., nums[0] ----------------------------
    # r12 = n is reused as the index: decrease it first, then use it,
    # so it runs n-1, n-2, ..., 0.
stored_all:
    lea   out(%rip), %rdi   # next free byte of out
print_loop:
    cmp   $0, %r12
    je    finish            # empty line: nothing to print
    dec   %r12
    mov   (%rbx,%r12,8), %rax   # nums[i]
    call  append_uint       # write it, rdi moves past the digits
    cmp   $0, %r12
    je    finish            # no space after the last one
    movb  $' ', (%rdi)
    inc   %rdi
    jmp   print_loop
finish:
    movb  $'\n', (%rdi)
    inc   %rdi
    # rdi is one past the last byte written, so the length is rdi - out.
    lea   out(%rip), %rsi   # write(1, out, rdi - out)
    mov   %rdi, %rdx
    sub   %rsi, %rdx
    mov   $1, %rax
    mov   $1, %rdi
    syscall
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall

# append_uint: write the decimal digits of rax at rdi, advance rdi.
# Changes rax, rcx, rdx, r8 (as in 05_letters.s).
#
# Dividing by 10 gives the digits last one first; pushing them and
# popping them back puts them in reading order. r8 counts the pushes so
# that the stack is back to the return address when ret runs.
append_uint:
    mov   $10, %rcx
    mov   $0, %r8           # number of digits
split:
    mov   $0, %rdx          # div divides rdx:rax, so clear the old remainder
    div   %rcx              # rax = quotient, rdx = last digit
    push  %rdx
    inc   %r8
    cmp   $0, %rax
    jne   split
emit:
    pop   %rax              # most significant digit first
    add   $'0', %al         # number -> character
    mov   %al, (%rdi)
    inc   %rdi
    dec   %r8
    jnz   emit
    ret
