# ex5_brackets.s: bracket matching using the CPU stack
#
#   echo "a[i] = f(x, {1, 2});" | ./ex5_brackets  -> OK
#   echo "(a[1)]"               | ./ex5_brackets  -> ERR 5
#   echo "f(x"                  | ./ex5_brackets  -> ERR 4
#
# Algorithm:
#   Opening bracket: push its expected closing bracket.
#   Closing bracket: pop and compare.
#   End of line:     the stack must be empty.
#
# Registers in the main loop (callee-saved):
#   r12 = i, the index of the character
#   r13 = address of line
#   r14 = number of bytes read
#   r15 = initial stack pointer (empty stack)
#   rbx = current character

    .equ MAXLINE, 256
    .equ NKINDS, 3

    .section .data
openers:
    .ascii "([{"
closers:
    .ascii ")]}"
ok:
    .ascii "OK\n"
    .equ OKLEN, . - ok
err:
    .asciz "ERR "

    .section .bss
line:
    .space MAXLINE
out:
    .space 32

    .section .text
    .global _start

_start:
    mov   %rsp, %r15         # remember empty stack position

    mov   $0, %rax           # read(0, line, MAXLINE)
    mov   $0, %rdi
    lea   line(%rip), %rsi
    mov   $MAXLINE, %rdx
    syscall
    mov   %rax, %r14         # bytes read

    lea   line(%rip), %r13
    mov   $0, %r12          # i = 0

scan:
    cmp   %r14, %r12
    jae   at_end

    movzbq (%r13,%r12), %rbx # c = line[i]
    cmp   $'\n', %rbx
    je    at_end

    # Is c an opening bracket?
    mov   %rbx, %rdi
    lea   openers(%rip), %rsi
    call  find
    cmp   $0, %rax
    jl    not_opener

    # Push the corresponding closing bracket
    lea   closers(%rip), %rcx
    movzbq (%rcx,%rax), %rdi

    sub   $8, %rsp           # padding for 16-byte alignment
    push  %rdi               # push expected closing bracket
    jmp   advance

not_opener:
    # Is c a closing bracket?
    mov   %rbx, %rdi
    lea   closers(%rip), %rsi
    call  find
    cmp   $0, %rax
    jl    advance            # neither: ignore it

    # Check whether the stack is empty
    cmp   %r15, %rsp
    je    error

    # Pop the expected closing bracket
    pop   %rax
    add   $8, %rsp           # remove alignment padding

    cmp   %rbx, %rax
    jne   error              # wrong closing bracket

advance:
    inc   %r12
    jmp   scan

at_end:
    cmp   %r15, %rsp
    jne   error              # brackets are still open

    mov   $1, %rax           # write(1, ok, OKLEN)
    mov   $1, %rdi
    lea   ok(%rip), %rsi
    mov   $OKLEN, %rdx
    syscall
    jmp   exit

error:
    mov   %r15, %rsp         # discard remaining brackets

    # Append "ERR "
    lea   err(%rip), %rdi
    lea   out(%rip), %rsi
    call  append_str

    # Append the position i + 1
    lea   1(%r12), %rdi
    mov   %rax, %rsi
    call  append_uint

    # Append newline
    movb  $'\n', (%rax)
    inc   %rax

    # Write the error message
    lea   out(%rip), %rsi
    mov   %rax, %rdx
    sub   %rsi, %rdx         # length = end - start

    mov   $1, %rax
    mov   $1, %rdi
    syscall

exit:
    mov   $60, %rax          # exit(0)
    mov   $0, %rdi
    syscall


# find(c, table): search a table of NKINDS bytes
#   in:      rdi = c, rsi = address of table
#   out:     rax = index, or -1 if not found
#   changes: rax

find:
    mov   $0, %rax

find_loop:
    cmp   $NKINDS, %rax
    jae   find_none
    cmp   %dil, (%rsi,%rax)
    je    find_done
    inc   %rax
    jmp   find_loop

find_none:
    mov   $-1, %rax

find_done:
    ret


# append_str(src, dest): copy a null-terminated string
#   in:      rdi = source, rsi = destination
#   out:     rax = address after last character written
#   changes: rax, rcx, rdi

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


# append_uint(n, dest): write an unsigned integer in decimal
#   in:      rdi = n, rsi = destination
#   out:     rax = address after last digit
#   changes: rax, rcx, rdx, rsi, r8, r9

append_uint:
    push  %rbp
    mov   %rsp, %rbp
    sub   $32, %rsp          # temporary digit buffer

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