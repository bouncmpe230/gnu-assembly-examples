# 05_letters.s: count the letters a-z on a line (Fall 2026)
#   echo "banana bread" | ./05_letters   ->   a=4 b=2 d=1 e=1 n=2 r=1
#
# Skills: an array indexed by a computed value, unsigned range checks,
#         building the output in a buffer, appending numbers to it.
#
# Registers:  rbx = address of counts   rsi = p, the position in the line
#             r12 = i, the letter index rdi = next free byte of out
# append_uint leaves rbx, r12 and rsi alone, so they survive the call.

    .equ  MAXLINE, 256

    .section .data
counts:
    # One counter per letter: counts[0] is 'a', ..., counts[25] is 'z'.
    # Each counter is 8 bytes (a full 64-bit register), so the array is
    # 26 * 8 bytes and counts[i] lives at counts + i*8.
    .zero 26*8              # 26 counters, all 0

    .section .bss
line:
    .space MAXLINE+1        # +1 for the 0 byte marking the end: read may
                            #   fill all MAXLINE bytes, then the 0 goes
                            #   into the one extra byte
out:
    # Why 26*24? The output has at most 26 entries, one per letter.
    # The longest possible entry is
    #     1 space + 1 letter + 1 '=' + 20 digits  =  23 bytes
    # (20 digits is the longest 64-bit number). 24 is a round number
    # above 23, and the spare bytes also hold the final '\n'.
    # In this program a count never passes 256 (3 digits), so far less
    # would do. But .bss space is free, and sizing for the worst case
    # means the buffer cannot overflow whatever the input is.
    .space 26*24            # room for every "x=count " entry

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall
    # read does not put a 0 after the text as C strings have. We add one
    # ourselves so the loop below knows where to stop.
    lea   line(%rip), %rsi
    add   %rax, %rsi        # end of the input (rax = bytes read)
    movb  $0, (%rsi)        # mark it with a 0 byte

    # ---- count -------------------------------------------------
    lea   line(%rip), %rsi  # p = line
    lea   counts(%rip), %rbx
count_loop:
    movzbq (%rsi), %rax     # c = *p (one byte, rest of rax zeroed)
    cmp   $0, %rax
    je    counted           # the 0 byte: end of the line
    # 'a'..'z' become 0..25 after c - 'a'. Anything below 'a' goes
    # negative = a huge unsigned number, so one "above 25" test rejects
    # both sides: spaces, digits, capitals, '\n', ...
    sub   $'a', %rax        # index = c - 'a'
    cmp   $25, %rax
    ja    not_letter        # c < 'a' or c > 'z'
    incq  (%rbx,%rax,8)     # counts[index]++   (address = rbx + rax*8;
                            #   the q in incq says "an 8-byte value")
not_letter:
    inc   %rsi
    jmp   count_loop

    # ---- print "x=count" for every letter that occurs ------------
counted:
    lea   out(%rip), %rdi   # next free byte
    mov   $0, %r12          # i = 0
print_loop:
    mov   (%rbx,%r12,8), %rax   # rax = counts[i]
    cmp   $0, %rax
    je    skip              # not in the line
    # Entries are separated by one space. If rdi is still at the start
    # of out, nothing has been written yet and this is the first entry.
    lea   out(%rip), %rcx
    cmp   %rcx, %rdi
    je    no_space          # first: no space
    movb  $' ', (%rdi)
    inc   %rdi
no_space:
    mov   %r12, %rcx
    add   $'a', %rcx        # the letter: index back to character
    mov   %cl, (%rdi)
    movb  $'=', 1(%rdi)     # 1(%rdi) = the byte after it
    add   $2, %rdi          # two bytes written
    call  append_uint       # write rax (the count), rdi moves past it
skip:
    inc   %r12
    cmp   $26, %r12
    jb    print_loop

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
# Changes rax, rcx, rdx, r8. The digits are reversed with the stack,
# as in the A86 number printer.
#
# Dividing by 10 gives the digits last one first: 305 gives 5, 0, 3.
# Pushing them and popping them back reverses the order: 3, 0, 5.
# r8 counts the pushes so that we pop exactly as many: ret takes its
# return address from the top of the stack, so every digit must be
# gone before it runs.
append_uint:
    mov   $10, %rcx
    mov   $0, %r8           # number of digits
split:
    mov   $0, %rdx          # div divides rdx:rax, so clear the old remainder
    div   %rcx              # rax = quotient, rdx = last digit
    push  %rdx
    inc   %r8
    cmp   $0, %rax          # tested after the push: 0 still gives one digit
    jne   split
emit:
    pop   %rax              # most significant digit first
    add   $'0', %al         # number -> character
    mov   %al, (%rdi)
    inc   %rdi
    dec   %r8
    jnz   emit              # dec sets the zero flag when r8 reaches 0
    ret
