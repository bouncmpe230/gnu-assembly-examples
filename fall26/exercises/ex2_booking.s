# ex2_booking.s: solution to Fall 2026 Exercise 2
#   echo "A-0-3 B-5-2 C-3-1" | ./ex2_booking   ->   AAAC.BB
#
# One meeting room. Each booking is ID-start-hours. Bookings do not
# overlap. Print one character per hour, from hour 0 up to the end of the
# last booking: the ID of the booking that holds the room, or '.'.
#
# Skills: a byte array as a timeline, filling a range of it, tokens with
#         '-' separators, keeping a running maximum.
#
# Plan: timeline[h] is the character to print for hour h. Start with
# '.' everywhere, then let each booking write its ID over its hours.
# The array is then already the output line.
#
# Registers:  rbx = address of timeline   rsi = p, the position in the line
#             r12 = ID of this booking    r13 = T, the latest end so far
#             r14 = start, then the hour being marked
#             r15 = end of this booking
# parse_uint changes only rax, rcx and rsi, so all of these survive it.

    .equ  MAXLINE, 256
    .equ  MAXT, 1000        # the longest timeline we support, in hours

    .section .bss
line:
    .space MAXLINE+1
timeline:
    .space MAXT+1           # one byte per hour, and a '\n'

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall

    lea   timeline(%rip), %rbx
    mov   $0, %rcx
fill:                       # every hour starts free
    movb  $'.', (%rbx,%rcx)
    inc   %rcx
    cmp   $MAXT, %rcx
    jb    fill

    lea   line(%rip), %rsi  # p
    mov   $0, %r13          # T = end of the last booking
token:
    movzbq (%rsi), %r12     # ID
    cmp   $'A', %r12        # a booking starts with a capital letter;
    jb    done              #   anything else ('\n') means the line is over
    cmp   $'Z', %r12
    ja    done
    add   $2, %rsi          # skip "X-"
    call  parse_uint        # rax = start
    mov   %rax, %r14        # save it: the next call overwrites rax
    inc   %rsi              # skip '-'
    call  parse_uint        # rax = hours
    lea   (%r14,%rax), %r15 # end = start + hours. lea used as an add that
                            #   puts the result in a third register
    cmp   %r13, %r15        # running maximum: T = max(T, end)
    jbe   mark              # end <= T: T stays
    mov   %r15, %r13        # new T
mark:                       # timeline[start .. end-1] = ID
    cmp   %r15, %r14
    jae   marked            # hour reached end: done (end itself is free)
    mov   %r12b, (%rbx,%r14) # r12b = low byte of r12, the ID character
    inc   %r14
    jmp   mark
marked:
    cmpb  $' ', (%rsi)      # a space: another booking follows
    jne   done
    inc   %rsi
    jmp   token

done:
    # Hours 0 .. T-1 are the answer. Put the '\n' right after them, at
    # index T, and print T + 1 bytes. (This is the +1 in MAXT+1.)
    movb  $'\n', (%rbx,%r13)
    lea   1(%r13), %rdx     # write(1, timeline, T + 1)
    mov   %rbx, %rsi
    mov   $1, %rax
    mov   $1, %rdi
    syscall
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall

# parse_uint: read the decimal number at rsi.
# Returns it in rax; rsi is left on the first non-digit. Changes rcx.
parse_uint:
    mov   $0, %rax          # value = 0
parse:
    movzbq (%rsi), %rcx
    sub   $'0', %rcx        # '0'..'9' -> 0..9; anything else -> above 9
    cmp   $9, %rcx          #   (unsigned), so one compare tests both ends
    ja    parsed
    imul  $10, %rax         # value = value * 10 + digit
    add   %rcx, %rax
    inc   %rsi
    jmp   parse
parsed:
    ret
