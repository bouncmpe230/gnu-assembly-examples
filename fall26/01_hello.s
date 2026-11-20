# 01_hello.s: Hello, World with the GNU assembler (Fall 2026)
#   as 01_hello.s -o 01_hello.o && ld 01_hello.o -o 01_hello && ./01_hello
#
# A program reaches the outside world only through system calls.
# A system call on x86-64 Linux:
#   rax           = which call          (0 = read, 1 = write, 60 = exit)
#   rdi, rsi, rdx = its 1st, 2nd, 3rd argument
#   syscall       = hand control to the kernel; the result comes back in
#                   rax (the kernel also overwrites rcx and r11)
#
#   read (fd, address, max bytes)       fd 0 = standard input
#   write(fd, address, length)          fd 1 = standard output
#   exit (code)
#
# Operand order in this (AT&T) syntax is  source, destination:
#   mov $1, %rax   means   rax = 1.     $ = a constant, % = a register.

    .section .data          # data with initial values, stored in the program
msg:                        # a label: a name for the address of what follows
    .ascii "Hello, World!\n"    # 13 characters + '\n' = 14 bytes

    .section .text          # the code
    .global _start          # let the linker see _start: execution begins there
_start:
    mov   $1, %rax          # system call 1 = write
    mov   $1, %rdi          # 1st argument: 1 = standard output
    lea   msg(%rip), %rsi   # 2nd: the ADDRESS of the text. lea computes an
                            #   address; mov msg(%rip) would load the bytes
                            #   stored there instead
    mov   $14, %rdx         # 3rd: length in bytes. write prints exactly this
                            #   many; it does not look for a 0 byte like
                            #   printf does, so we have to count
    syscall

    mov   $60, %rax         # system call 60 = exit
    mov   $0, %rdi          # exit code 0 = success
    syscall                 # does not return. Without it the CPU would keep
                            #   executing whatever bytes follow the code
