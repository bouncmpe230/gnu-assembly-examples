# ex3_rooms.s: solution to Fall 2026 Exercise 3
#   echo "A-0-0-3 B-1-1-2 C-0-4-1 D-2-2-3" | ./ex3_rooms
#   AAA.C
#   .BB..
#   ..DDD
#
# Three rooms, numbered 0 to 2. Each booking is ID-room-start-hours.
# Bookings in the same room do not overlap. Print one line per room; all
# lines have the same length T, the end of the latest booking.
#
# Skills: a 2-D byte array stored row after row, row * WIDTH + column.
#
# Memory is one long line of bytes, so a 2-D array is stored as row 0,
# then row 1, then row 2, each WIDTH bytes long. Row r therefore starts
# at byte r * WIDTH, and grid[r][c] is byte r * WIDTH + c.
#
# Registers:  rbx = address of grid       rsi = p, the position in the line
#             r12 = ID of this booking    r13 = T, the latest end so far
#             r8  = room * WIDTH          r14 = start, then the hour marked
#             r15 = end of this booking
# parse_uint changes only rax, rcx and rsi, so all of these survive it.

    .equ  MAXLINE, 256
    .equ  WIDTH, 1001       # one row: up to 1000 hours and a '\n'
    .equ  ROWS, 3

    .section .bss
line:
    .space MAXLINE+1
grid:
    .space ROWS*WIDTH       # 3 rows of 1001 bytes, one after another

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall

    lea   grid(%rip), %rbx
    mov   $0, %rcx
fill:                       # every cell starts free
    movb  $'.', (%rbx,%rcx) # the rows are contiguous, so one loop over
    inc   %rcx              #   all ROWS*WIDTH bytes fills the whole grid
    cmp   $ROWS*WIDTH, %rcx
    jb    fill

    lea   line(%rip), %rsi
    mov   $0, %r13          # T
token:
    movzbq (%rsi), %r12     # ID
    cmp   $'A', %r12        # a booking starts with a capital letter;
    jb    done              #   anything else ('\n') means the line is over
    cmp   $'Z', %r12
    ja    done
    add   $2, %rsi          # skip "X-"
    call  parse_uint        # room
    imul  $WIDTH, %rax, %r8 # r8 = room * WIDTH: start of the row
    inc   %rsi              # skip '-'
    call  parse_uint        # start
    mov   %rax, %r14        # save it: the next call overwrites rax
    inc   %rsi              # skip '-'
    call  parse_uint        # hours
    lea   (%r14,%rax), %r15 # end = start + hours
    cmp   %r13, %r15        # running maximum: T = max(T, end)
    jbe   mark
    mov   %r15, %r13
mark:                       # grid[room][start .. end-1] = ID
    cmp   %r15, %r14
    jae   marked
    lea   (%r8,%r14), %rax  # room * WIDTH + hour
    mov   %r12b, (%rbx,%rax) # r12b = low byte of r12, the ID character
    inc   %r14
    jmp   mark
marked:
    cmpb  $' ', (%rsi)      # a space: another booking follows
    jne   done
    inc   %rsi
    jmp   token

done:
    # Print each row as its own line: the first T bytes of the row, then
    # a '\n' written at column T. T is the same for every row, so the
    # lines come out equally long. Column T always exists because WIDTH
    # is one more than the 1000 hours.
    mov   $0, %r12          # row (the ID in r12 is no longer needed)
print_row:
    imul  $WIDTH, %r12, %rsi
    add   %rbx, %rsi        # rsi = &grid[row][0]
    movb  $'\n', (%rsi,%r13)
    lea   1(%r13), %rdx     # T characters and '\n'
    mov   $1, %rax          # write(1, &grid[row][0], T + 1)
    mov   $1, %rdi
    syscall
    inc   %r12
    cmp   $ROWS, %r12
    jb    print_row

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
