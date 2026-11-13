### File I/O: copy a file  (usage: ./16.copy SOURCE DEST)
###
###   open(path, flags, mode) -> file descriptor   syscall 2
###   read(fd, buf, count)    -> bytes read        syscall 0   (0 = end of file)
###   write(fd, buf, count)   -> bytes written     syscall 1
###   close(fd)                                    syscall 3
###
### A syscall that fails returns a negative number: -errno
### (for example -2 = ENOENT, "no such file"). Always check!
###
### Syscall arguments go in %rdi, %rsi, %rdx, %r10, %r8, %r9. The kernel
### preserves every register except %rax (result), %rcx and %r11.

.equ SYS_READ,  0               # .equ gives a name to a constant
.equ SYS_WRITE, 1
.equ SYS_OPEN,  2
.equ SYS_CLOSE, 3
.equ SYS_EXIT,  60

.equ O_RDONLY,  0               # flags for open (from <fcntl.h>)
.equ O_WRONLY,  1
.equ O_CREAT,   0100            # a leading 0 means octal
.equ O_TRUNC,   01000

.equ STDERR,    2
.equ BUFSIZE,   4096

.section .data
usage_msg: .ascii "usage: 16.copy SOURCE DEST\n"
.equ USAGE_LEN, . - usage_msg   # . is the current address: length = end - start
error_msg: .ascii "16.copy: error (see exit status for errno)\n"
.equ ERROR_LEN, . - error_msg

.section .bss
buf: .space BUFSIZE

.section .text
.global _start

_start:
    cmpq $3, (%rsp)             # argc must be 3: program, SOURCE, DEST
    jne usage

    ### r12 = open(argv[1], O_RDONLY)
    mov $SYS_OPEN, %rax
    mov 16(%rsp), %rdi
    mov $O_RDONLY, %rsi
    syscall
    test %rax, %rax
    js fail
    mov %rax, %r12

    ### r13 = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644)
    mov $SYS_OPEN, %rax
    mov 24(%rsp), %rdi
    mov $(O_WRONLY | O_CREAT | O_TRUNC), %rsi   # computed by the assembler
    mov $0644, %rdx             # permissions rw-r--r-- (octal)
    syscall
    test %rax, %rax
    js fail
    mov %rax, %r13

copy_loop:
    ### n = read(r12, buf, BUFSIZE)
    mov $SYS_READ, %rax
    mov %r12, %rdi
    lea buf(%rip), %rsi
    mov $BUFSIZE, %rdx
    syscall
    test %rax, %rax
    jz copy_done                # 0: end of file
    js fail                     # < 0: error

    ### write(r13, buf, n)
    mov %rax, %rdx
    mov $SYS_WRITE, %rax
    mov %r13, %rdi
    lea buf(%rip), %rsi
    syscall
    test %rax, %rax
    js fail
    jmp copy_loop

copy_done:
    mov $SYS_CLOSE, %rax
    mov %r12, %rdi
    syscall
    mov $SYS_CLOSE, %rax
    mov %r13, %rdi
    syscall

    mov $SYS_EXIT, %rax
    xor %rdi, %rdi
    syscall

fail:                           # %rax = -errno
    neg %rax
    mov %rax, %rbx              # exit status = errno, check it with: echo $?
    mov $SYS_WRITE, %rax
    mov $STDERR, %rdi
    lea error_msg(%rip), %rsi
    mov $ERROR_LEN, %rdx
    syscall
    mov $SYS_EXIT, %rax
    mov %rbx, %rdi
    syscall

usage:
    mov $SYS_WRITE, %rax
    mov $STDERR, %rdi
    lea usage_msg(%rip), %rsi
    mov $USAGE_LEN, %rdx
    syscall
    mov $SYS_EXIT, %rax
    mov $1, %rdi
    syscall
