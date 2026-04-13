# GNU Assembly (GAS) Quick Guide

## What is GNU Assembler?

GNU Assembler (GAS):
- Part of the GNU toolchain
- Converts **assembly → machine code (object file)**
- Uses **AT&T syntax** 

---

## Basic Structure of a Program

```asm
.section .data
msg:
    .asciz "Hello, world!\n"

.section .text
.global _start

_start:
    # write syscall
    mov $1, %rax        # syscall: write
    mov $1, %rdi        # stdout
    lea msg(%rip), %rsi # address of message
    mov $14, %rdx       # length
    syscall

    # exit syscall
    mov $60, %rax
    xor %rdi, %rdi
    syscall


````

---

## Compilation (Required)

```bash
as -o program.o program.s
ld -o program program.o
./program
```

---

## AT&T Syntax Rules

### Operand Order

```
source → destination
```

```asm
mov $5, %rax   # rax = 5
```

---

### Prefixes

| Type      | Prefix | Example |
| --------- | ------ | ------- |
| Register  | `%`    | `%rax`  |
| Immediate | `$`    | `$10`   |

```asm
mov $10, %rax
```

---

## Memory Addressing

Format:

```
offset(base, index, scale)
```

Example:

```asm
mov (%rax), %rbx
mov 8(%rbp), %rax
mov (%rax,%rbx,4), %rcx
```

Equivalent to:

```
[base + index * scale + offset]
```

---

## Operand Sizes

| Suffix | Size   |
| ------ | ------ |
| b      | 8-bit  |
| w      | 16-bit |
| l      | 32-bit |
| q      | 64-bit |

```asm
movb $1, %al
movl $10, %eax
movq $100, %rax
```

---

## Registers (x86-64)

| Register | Purpose                       |
| -------- | ----------------------------- |
| `%rax`   | return value / syscall number |
| `%rdi`   | argument 1                    |
| `%rsi`   | argument 2                    |
| `%rdx`   | argument 3                    |
| `%rsp`   | stack pointer                 |
| `%rbp`   | base pointer                  |

---

## System Calls (Linux x86-64)

| Syscall | Number |
| ------- | ------ |
| read    | 0      |
| write   | 1      |
| exit    | 60     |

Example:

```asm
mov $1, %rax   # write
mov $1, %rdi   # stdout
lea msg(%rip), %rsi
mov $14, %rdx
syscall
```

---

## Input Example

```asm
.section .bss
buffer: .space 256

mov $0, %rax        # read
mov $0, %rdi        # stdin
lea buffer(%rip), %rsi
mov $256, %rdx
syscall
```

---

## Output Example

```asm
mov $1, %rax
mov $1, %rdi
lea buffer(%rip), %rsi
mov %rdx, %rdx   # length already in rdx
syscall
```

---

## Sections

| Section | Purpose            |
| ------- | ------------------ |
| `.text` | code               |
| `.data` | initialized data   |
| `.bss`  | uninitialized data |

---

## Stack Basics

```asm
push %rax
pop %rbx
```

Stack grows **downward**.

---

## Common Mistakes

### Wrong operand order

```asm
mov %rax, $5   # WRONG
```

### Missing prefixes

```asm
mov 5, rax     # WRONG
```

### Forgetting exit

→ program crashes or hangs

---

## Debugging

```bash
gdb ./program
```

