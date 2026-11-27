# ex4_merge.s: solution to Exercise 4 (PS2 v2)
#   echo "1 4 9 20 | 2 3 10 11 30" | ./ex4_merge   ->   1 2 3 4 9 10 11 20 30
#
# The line holds two lists of numbers, separated by " | ". Each list is
# already in ascending order and has 1 to 16 numbers. Print all numbers
# as one list in ascending order.
#
# Merge: look at the front of both lists, move the smaller number to the
# result, and advance in the list it came from. When one list is used up,
# the rest of the other follows.
#
# Concepts: several arrays with their own lengths and indexes, a
# procedure that fills an array and saves callee-saved registers,
# scaled indexing.
#
# Variables:
#   a[], na     the first list and its length
#   b[], nb     the second list and its length
#   c[]         the merged list; its length is na + nb
#
# Registers in the merge (no calls inside, so any register will do):
#   rsi = &a[0]   rdi = &b[0]   r11 = &c[0]
#   r8  = i (next of a)   r9 = j (next of b)   r10 = k (next free of c)

    .equ  MAXLINE, 512
    .equ  MAXN, 16          # numbers per list

    .section .bss
line:
    .space MAXLINE+1
a:
    .space MAXN*8
b:
    .space MAXN*8
c:
    .space 2*MAXN*8
na:
    .space 8
nb:
    .space 8
out:
    .space MAXLINE

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall

    # ---- read the two lists ---------------------------------------
    lea   line(%rip), %rdi
    lea   a(%rip), %rsi
    call  read_list         # rax = how many, rdx = position after them
    mov   %rax, na(%rip)
    lea   3(%rdx), %rdi     # skip " | "
    lea   b(%rip), %rsi
    call  read_list
    mov   %rax, nb(%rip)

    # ---- merge a and b into c -------------------------------------
    lea   a(%rip), %rsi
    lea   b(%rip), %rdi
    lea   c(%rip), %r11
    mov   $0, %r8           # i
    mov   $0, %r9           # j
    mov   $0, %r10          # k
merge:
    cmp   na(%rip), %r8
    jb    a_has_more
    cmp   nb(%rip), %r9
    jae   merged            # both lists are used up
    jmp   take_b            # only b is left
a_has_more:
    cmp   nb(%rip), %r9
    jae   take_a            # only a is left
    mov   (%rsi,%r8,8), %rax
    cmp   (%rdi,%r9,8), %rax
    jbe   take_a            # a[i] <= b[j]
take_b:
    mov   (%rdi,%r9,8), %rax
    inc   %r9
    jmp   store
take_a:
    mov   (%rsi,%r8,8), %rax
    inc   %r8
store:
    mov   %rax, (%r11,%r10,8) # c[k] = the smaller one
    inc   %r10
    jmp   merge
merged:

    # ---- print c: numbers separated by single spaces --------------
    # append_uint is called here, so the loop values move to
    # callee-saved registers.
    mov   %r10, %r14        # how many
    mov   $0, %r12          # k
    lea   out(%rip), %r13   # next free byte of the output
print_next:
    lea   c(%rip), %rax
    mov   (%rax,%r12,8), %rdi
    mov   %r13, %rsi
    call  append_uint
    mov   %rax, %r13
    inc   %r12
    cmp   %r14, %r12
    jae   print
    movb  $' ', (%r13)      # a space only between numbers
    inc   %r13
    jmp   print_next
print:
    movb  $'\n', (%r13)
    inc   %r13
    lea   out(%rip), %rsi   # write(1, out, r13 - out)
    mov   %r13, %rdx
    sub   %rsi, %rdx
    mov   $1, %rax
    mov   $1, %rdi
    syscall
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall

# read_list(p, array): read numbers separated by single spaces into array
#   in:       rdi = address of the first digit, rsi = address of the array
#   out:      rax = how many numbers were stored
#             rdx = address of the character after the last number
#   changes:  rax, rcx, rdx, rdi
# It calls parse_uint, so what it needs afterwards is kept in rbx, r12,
# r13, which it saves on entry and restores before returning.
read_list:
    push  %rbx
    push  %r12
    push  %r13
    mov   %rsi, %rbx        # the array
    mov   $0, %r12          # count
    mov   %rdi, %r13        # p
rl_next:
    mov   %r13, %rdi
    call  parse_uint        # rax = value, rdx = position after it
    mov   %rax, (%rbx,%r12,8) # array[count] = value
    inc   %r12
    mov   %rdx, %r13
    cmpb  $' ', (%r13)
    jne   rl_done           # not a space: the list is over
    movzbq 1(%r13), %rax
    sub   $'0', %rax
    cmp   $9, %rax
    ja    rl_done           # a space, but no digit after it: " |"
    inc   %r13              # skip the space
    jmp   rl_next
rl_done:
    mov   %r12, %rax
    mov   %r13, %rdx
    pop   %r13              # restore in reverse order
    pop   %r12
    pop   %rbx
    ret

# parse_uint(p): read the decimal number that starts at p
#   in:       rdi = address of the first digit
#   out:      rax = value, rdx = address of the first non-digit
#   changes:  rax, rcx, rdx
parse_uint:
    mov   $0, %rax
    mov   %rdi, %rdx
parse:
    movzbq (%rdx), %rcx
    sub   $'0', %rcx
    cmp   $9, %rcx
    ja    parsed
    imul  $10, %rax
    add   %rcx, %rax
    inc   %rdx
    jmp   parse
parsed:
    ret

# append_uint(n, dest): write n in decimal at dest
#   in:       rdi = n, rsi = address to write to
#   out:      rax = address after the last digit
#   changes:  rax, rcx, rdx, rsi, r8, r9
append_uint:
    push  %rbp
    mov   %rsp, %rbp
    sub   $32, %rsp
    mov   %rdi, %rax
    lea   -1(%rbp), %r8
    mov   %r8, %r9
    mov   $10, %rcx
split:
    mov   $0, %rdx
    div   %rcx
    add   $'0', %dl
    mov   %dl, (%r9)
    dec   %r9
    cmp   $0, %rax
    jne   split
copy:
    inc   %r9
    mov   (%r9), %al
    mov   %al, (%rsi)
    inc   %rsi
    cmp   %r8, %r9
    jne   copy
    mov   %rsi, %rax
    leave
    ret
