# ex5_brackets.s: solution to Exercise 5 (PS2 v2)
#   echo "a[i] = f(x, {1, 2});" | ./ex5_brackets   ->   OK
#   echo "(a[1)]"               | ./ex5_brackets   ->   ERR 5
#   echo "f(x"                  | ./ex5_brackets   ->   ERR 4
#
# Check the brackets ( ) [ ] { } on one line. Every other character is
# ignored. Print OK if every bracket is closed by the right one, in the
# right order. Otherwise print ERR and the position (the first character
# is 1) of the first closing bracket that is wrong. If the line ends
# while brackets are still open, the position is one past the last
# character.
#
# Algorithm: keep a stack of the closing brackets that are still expected.
#   an opening bracket:  push its partner
#   a closing bracket:   pop; it must be this very character
#   end of the line:     the stack must be empty
#
# Concepts: a data structure (an array and a depth) hidden behind
# procedures, constant tables, a search procedure used for two tables,
# a main loop whose values live in callee-saved registers.
#
# Variables:
#   openers, closers   two tables of 3 bytes: closers[i] closes openers[i]
#   stack[], depth     the expected closing brackets
#
# Registers in the main loop (all callee-saved):
#   r12 = i, the index of the character     r13 = &line[0]
#   r14 = number of bytes read              rbx = the character

    .equ  MAXLINE, 256
    .equ  NKINDS, 3         # kinds of brackets

    .section .data
openers:
    .ascii "([{"
closers:
    .ascii ")]}"
ok:
    .ascii "OK\n"
    .equ  OKLEN, . - ok
err:
    .asciz "ERR "

    .section .bss
line:
    .space MAXLINE
stack:
    .space MAXLINE          # one byte per open bracket
depth:
    .space 8                # how many are on the stack
out:
    .space 32

    .section .text
    .global _start
_start:
    mov   $0, %rax          # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall
    mov   %rax, %r14        # bytes read

    lea   line(%rip), %r13
    mov   $0, %r12          # i
scan:
    cmp   %r14, %r12
    jae   at_end
    movzbq (%r13,%r12), %rbx # c = line[i]
    cmp   $'\n', %rbx
    je    at_end

    mov   %rbx, %rdi
    lea   openers(%rip), %rsi
    call  find              # is c an opening bracket?
    cmp   $0, %rax
    jl    not_opener
    lea   closers(%rip), %rcx
    movzbq (%rcx,%rax), %rdi # its partner
    call  st_push
    jmp   advance
not_opener:
    mov   %rbx, %rdi
    lea   closers(%rip), %rsi
    call  find              # is c a closing bracket?
    cmp   $0, %rax
    jl    advance           # neither: ignore it
    call  st_pop            # the bracket that is expected here
    cmp   %rbx, %rax
    jne   error             # another one, or none at all
advance:
    inc   %r12
    jmp   scan

at_end:
    cmpq  $0, depth(%rip)
    jne   error             # brackets are still open
    mov   $1, %rax          # write(1, ok, OKLEN)
    mov   $1, %rdi
    lea   ok(%rip), %rsi
    mov   $OKLEN, %rdx
    syscall
    jmp   exit

error:                      # "ERR ", the position i + 1, a newline
    lea   err(%rip), %rdi
    lea   out(%rip), %rsi
    call  append_str
    lea   1(%r12), %rdi
    mov   %rax, %rsi
    call  append_uint
    movb  $'\n', (%rax)
    inc   %rax
    lea   out(%rip), %rsi
    mov   %rax, %rdx
    sub   %rsi, %rdx
    mov   $1, %rax
    mov   $1, %rdi
    syscall
exit:
    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall

# find(c, table): look for a character in a table of NKINDS bytes
#   in:       rdi = c, rsi = address of the table
#   out:      rax = its index (0..NKINDS-1), or -1 if it is not there
#   changes:  rax
find:
    mov   $0, %rax
find_loop:
    cmp   $NKINDS, %rax
    jae   find_none
    cmp   %dil, (%rsi,%rax) # table[rax] == c ?
    je    find_done
    inc   %rax
    jmp   find_loop
find_none:
    mov   $-1, %rax
find_done:
    ret

# st_push(c): put a character on the stack
#   in:       rdi = c
#   changes:  rax, rcx
st_push:
    lea   stack(%rip), %rax
    mov   depth(%rip), %rcx
    mov   %dil, (%rax,%rcx) # stack[depth] = c
    incq  depth(%rip)
    ret

# st_pop(): take the top character off the stack
#   out:      rax = the character, or 0 if the stack is empty
#   changes:  rax, rcx, rdx
st_pop:
    mov   $0, %rax
    mov   depth(%rip), %rcx
    cmp   $0, %rcx
    je    pop_done          # empty
    dec   %rcx
    mov   %rcx, depth(%rip)
    lea   stack(%rip), %rdx
    movzbq (%rdx,%rcx), %rax # stack[depth]
pop_done:
    ret

# append_str(src, dest): copy the text at src, up to its 0 byte, to dest
#   in:       rdi = address of the text, rsi = address to write to
#   out:      rax = address after the last character written
#   changes:  rax, rcx, rdi
append_str:
    mov   %rsi, %rax
as_loop:
    mov   (%rdi), %cl
    cmp   $0, %cl
    je    as_done
    mov   %cl, (%rax)
    inc   %rdi
    inc   %rax
    jmp   as_loop
as_done:
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
