# 04_sum.s: add up the numbers on one line (Fall 2026)
#   echo "12 7 300" | ./04_sum   ->   319
#
# Skills: reading a line, splitting it into tokens, string -> integer,
#         integer -> string.
#
# Registers:  rsi = p, the position in the line     rbx = sum
#             rcx = value of the number being read  rax = current character

    .equ  MAXLINE, 256      # a named constant, like #define in C

    .section .bss
line:
    .space MAXLINE
out:
    .space 32               # the sum as text. The largest 64-bit number,
                            #   18446744073709551615, has 20 digits; with
                            #   the '\n' that is 21 bytes. 32 is simply a
                            #   round size that is surely enough

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall

    lea   line(%rip), %rsi  # p = line
    mov   $0, %rbx          # sum = 0
token:                      # find the start of the next number
    movzbq (%rsi), %rax     # c = *p. movzbq loads ONE byte and zeroes the
                            #   other 7 bytes of rax
    cmp   $' ', %al
    jne   not_space
    inc   %rsi              # skip one space
    jmp   token
not_space:
    # Is c a digit? One unsigned compare answers it. After c - '0' the
    # digits '0'..'9' become 0..9. Anything below '0' (such as '\n')
    # goes negative, which read as unsigned is a huge number. So
    # "above 9" (ja) means "not a digit".
    sub   $'0', %rax        # c - '0'
    cmp   $9, %rax
    ja    done              # not a digit: end of line

    # string -> integer: value = value * 10 + digit
    # "300":  0 -> 3 -> 30 -> 300
    mov   $0, %rcx          # value = 0
digit:
    movzbq (%rsi), %rax
    sub   $'0', %rax        # character -> number, and the same digit test
    cmp   $9, %rax          # unsigned compare
    ja    number_end        # not a digit: stop
    imul  $10, %rcx
    add   %rax, %rcx
    inc   %rsi
    jmp   digit
number_end:
    add   %rcx, %rbx        # sum += value
    jmp   token

done:
    # integer -> string: divide by 10 again and again; each remainder is
    # one digit. They come out last digit first (319 gives 9, 1, 3), so
    # fill the buffer from its end backwards.
    mov   %rbx, %rax
    lea   out+32(%rip), %rdi # one past the last byte of out
    dec   %rdi
    movb  $'\n', (%rdi)     # the '\n' goes in the very last byte
    mov   $10, %rcx
divide:
    mov   $0, %rdx          # div divides the 128-bit number rdx:rax, and
                            #   rdx still holds the previous remainder, so
                            #   clear it every time
    div   %rcx              # rax = quotient, rdx = remainder (one digit)
    add   $'0', %dl         # remainder to character
    dec   %rdi
    mov   %dl, (%rdi)
    cmp   $0, %rax          # tested after the first digit is stored, so a
    jne   divide            #   sum of 0 still prints "0"

    # The text starts at rdi (wherever the first digit landed) and runs
    # to the end of out, so its length is end - rdi.
    mov   %rdi, %rsi        # write(1, rdi,
    lea   out+32(%rip), %rdx
    sub   %rdi, %rdx        #   end - rdi)
    mov   $1, %rax
    mov   $1, %rdi          # only now is rdi free to hold the 1
    syscall

    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall
