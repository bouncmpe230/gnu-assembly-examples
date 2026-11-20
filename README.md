# GNU Assembly (GAS) Quick Guide

## What is GNU Assembler?

GNU Assembler (GAS):
- Part of the GNU toolchain
- Converts **assembly → machine code (object file)**
- Uses **AT&T syntax** 

All examples target **x86-64 Linux**.

---

## Examples

| File | Topics |
| ---- | ------ |
| `1.hello.s` | `write` and `exit` syscalls |
| `2.inp.s` | `read` syscall, echoing input back |
| `3.cmp_imm.s` | `cmp` / `jge`, integer → decimal string with `div` |
| `4.cmp_int.s` | parsing integers from input (string → integer) |
| `5.reverse.s` | indexed addressing, counting loop |
| `6.upper.s` | character ranges, unsigned compares, modifying memory |
| `7.spaces.s` | looping until the 0 terminator, counting |
| `8.cmp_int.s` | a first function: `call` / `ret`, arguments, return values |
| `9.functions.s` | calling convention: argument and return registers, caller- and callee-saved registers, 7th argument on the stack |
| `10.stack_frame.s` | stack frames, local variables, passing a pointer to a local, signed division (`cqo` / `idiv`) |
| `11.factorial.s` | recursion, saving values on the stack |
| `12.fibonacci.s` | recursion with two calls, callee-saved registers, stack alignment |
| `13.array_sort.s` | arrays of 64-bit integers, scaled indexing, bubble sort, `.equ` |
| `14.bits.s` | `and` / `or` / `xor` / `not`, `shl` / `shr` / `sar`, popcount, `.macro` |
| `15.args.s` | command-line arguments (`argc` / `argv` on the stack) |
| `16.copy.s` | file I/O (`open` / `read` / `write` / `close`), error handling, exit status |
| `17.printf.s` | calling C library functions (`printf`, `scanf`) from assembly |
| `18.main.c` + `18.funcs.s` | calling assembly functions from C |

---

## Fall 2026 Problem Session (`fall26/`)

The programs shown in the first assembly problem session. They use only
`as` and `ld` (no C library), and every line is commented.

| File | Topics | Run |
| ---- | ------ | --- |
| `fall26/01_hello.s` | `write` and `exit` syscalls | `./01_hello` |
| `fall26/02_digits.s` | loop, indexed byte stores, building output in a buffer | `./02_digits` |
| `fall26/03_echo.s` | `read` syscall, a first `call` / `ret` | `echo hi \| ./03_echo` |
| `fall26/04_sum.s` | splitting a line into tokens, string → integer, integer → string | `echo "12 7 300" \| ./04_sum` |
| `fall26/05_letters.s` | array of counters, unsigned range checks, output buffer | `echo "banana bread" \| ./05_letters` |
| `fall26/06_winner.s` | array of records, field offsets with `.equ`, choosing with tie-breaks | `./06_winner` |

### Exercises (`fall26/exercises/`)

Try each exercise yourself before reading its solution.

| Solution | Exercise | Example |
| -------- | -------- | ------- |
| `ex1_reverse.s` | Read up to 32 numbers from one line into an array, then print them in reverse order, separated by single spaces. | `echo "5 12 300 7" \| ./ex1_reverse` → `7 300 12 5` |
| `ex2_booking.s` | One meeting room. Each booking is `ID-start-hours`; bookings do not overlap. Print one character per hour, from hour 0 to the end of the last booking: the ID of the booking that holds the room, or `.`. | `echo "A-0-3 B-5-2 C-3-1" \| ./ex2_booking` → `AAAC.BB` |
| `ex3_rooms.s` | Three rooms, numbered 0 to 2. Each booking is `ID-room-start-hours`; bookings in the same room do not overlap. Print one line per room, all of the same length (the end of the latest booking). | `echo "A-0-0-3 B-1-1-2 C-0-4-1 D-2-2-3" \| ./ex3_rooms` → `AAA.C` / `.BB..` / `..DDD` |

### Building

Both directories have a Makefile that builds every `.s` file in it with
`as` and `ld`:

```bash
cd fall26           # or fall26/exercises
make              # builds all programs
make clean        # removes them
```

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
```

---

## Building and Running

```bash
as -o program.o program.s
ld -o program program.o
./program
```

Examples that use the C library (17, 18) are built with `gcc`, which links it in:

```bash
gcc -o 17.printf 17.printf.s
gcc -o 18.c_calls_asm 18.main.c 18.funcs.s
```

### On macOS (Intel or Apple Silicon) or Windows

Use an x86-64 Linux container:

```bash
docker run --rm -it --platform linux/amd64 -v "$PWD":/work -w /work ubuntu:24.04 bash
apt-get update && apt-get install -y gcc gdb    # once per container
```

On Apple Silicon, Docker runs x86-64 programs through Rosetta. If a program
fails with `rosetta error: bss_size overflow`, it has `.rodata` and `.bss`
but no `.data`. This is a Rosetta limitation; the program is fine on real
Linux. Moving the strings from `.rodata` to `.data` avoids it. `gdb` does
not work under Rosetta either; use the online debugger below instead.

### An online assembly editor and GDB-like debugger

https://app.x64.halb.it/

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

Element `i` of an array of 8-byte values at `%rdi` is `(%rdi,%rcx,8)` when `%rcx = i`.

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
| `%rcx`   | argument 4                    |
| `%r8`    | argument 5                    |
| `%r9`    | argument 6                    |
| `%rsp`   | stack pointer                 |
| `%rbp`   | base pointer                  |

---

## Calling Convention (System V AMD64)

| | Registers |
| --- | --- |
| Arguments 1–6 | `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9`; more go on the stack |
| Return value | `%rax` |
| Caller-saved: a `call` may change them | `%rax`, `%rcx`, `%rdx`, `%rsi`, `%rdi`, `%r8`–`%r11` |
| Callee-saved: a function must restore them | `%rbx`, `%rbp`, `%r12`–`%r15` |

- `%rsp` must be a multiple of 16 right before every `call`. It is at `_start`;
  inside a function it is 8 off (the return address), so push an odd number of
  8-byte values (e.g. just `push %rbp`) before calling other functions.
- Syscalls are different: arguments go in `%rdi`, `%rsi`, `%rdx`, **`%r10`**, `%r8`,
  `%r9`, and the kernel changes only `%rax`, `%rcx` and `%r11`.

A function with local variables:

```asm
func:
    push %rbp           # prologue
    mov %rsp, %rbp
    sub $16, %rsp       # two 8-byte locals at -8(%rbp) and -16(%rbp)
    ...
    leave               # epilogue: mov %rbp, %rsp ; pop %rbp
    ret
```

---

## System Calls (Linux x86-64)

| Syscall | Number |
| ------- | ------ |
| read    | 0      |
| write   | 1      |
| open    | 2      |
| close   | 3      |
| exit    | 60     |

On error, a syscall returns a negative number (`-errno`) in `%rax`.

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
syscall             # rax = number of bytes read
```

---

## Output Example

```asm
mov %rax, %rdx      # length = bytes read (save it before %rax is overwritten)
mov $1, %rax        # write
mov $1, %rdi
lea buffer(%rip), %rsi
syscall
```

---

## Sections

| Section   | Purpose                        |
| --------- | ------------------------------ |
| `.text`   | code                           |
| `.data`   | initialized data               |
| `.rodata` | read-only data (constants)     |
| `.bss`    | uninitialized data (zeroed)    |

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

### Printing a whole buffer instead of its contents

Writing 32 bytes when only 3 are filled also prints the rest of the buffer.
The extra NUL bytes are invisible in a terminal but are still there:

```bash
./program | od -c
```

### Expecting a register to survive a `call` or `syscall`

`syscall` overwrites `%rax`, `%rcx` and `%r11`. A `call` may overwrite every
caller-saved register. Keep values you still need in callee-saved registers
or on the stack.

### Mixing signed and unsigned jumps

`jl` / `jg` / `jle` / `jge` compare signed numbers; `jb` / `ja` / `jbe` / `jae`
compare unsigned ones. `-1` is less than `0` for `jl`, but larger for `jb`.

---

## Debugging

```bash
as -g -o program.o program.s    # -g: lets gdb step through the source
ld -o program program.o
gdb ./program
```

```
(gdb) break _start
(gdb) run
(gdb) stepi                  # execute one instruction
(gdb) info registers rax rdi
(gdb) x/s &msg               # show memory at msg as a string
```
