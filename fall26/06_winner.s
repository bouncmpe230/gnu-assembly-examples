# 06_winner.s: pick the best record, with tie-breaking (Fall 2026)
#   ./06_winner   ->   R
#
# A programming contest. Each team has a letter, the number of problems
# solved and a penalty time. The winner solved the most problems.
# Ties: the smaller penalty wins. Still tied: the team listed first wins.
#
# Skills: an array of records, field offsets with .equ, scaled
#         indexing, comparing on several keys.
#
# Registers:  rbx = &teams[0]     rcx = i
#             rsi = &teams[i]     r12 = address of the best team so far

    # A record is like a C struct: three fields stored one after another.
    # Every field is a .quad (8 bytes), so they start at bytes 0, 8 and
    # 16 of the record, and a whole record is 3 * 8 = 24 bytes.
    # (The ID is one character, but keeping all fields the same size
    # keeps the offsets simple.)
    .equ  ID, 0             # field offsets
    .equ  SOLVED, 8
    .equ  PENALTY, 16
    .equ  REC, 24           # record size

    .section .data
teams:                      # ID, SOLVED, PENALTY
    .quad 'K', 5, 300
    .quad 'B', 7, 410
    .quad 'R', 7, 380       # wins: 7 solved, penalty 380, listed before M
    .quad 'M', 7, 380
    .equ  NTEAMS, 4         # must match the number of rows above
out:
    .ascii "?\n"            # the '?' is overwritten with the answer

    .section .text
    .global _start
_start:
    lea   teams(%rip), %rbx # rbx = &teams[0]
    mov   %rbx, %r12        # best = &teams[0]
    mov   $1, %rcx          # i = 1: team 0 is already the best so far
loop:
    cmp   $NTEAMS, %rcx
    jae   found             # i >= NTEAMS: all teams seen
    # teams[i] starts at teams + i*24. The scale in (base,index,scale)
    # can only be 1, 2, 4 or 8, so for 24 we multiply ourselves.
    imul  $REC, %rcx, %rsi  # rsi = i * REC
    add   %rbx, %rsi        # rsi = &teams[i]

    # First key: problems solved. Jumps do not change the flags, so the
    # ja and the jb below both test the result of this one cmp.
    mov   SOLVED(%rsi), %rax    # SOLVED(%rsi) = the field at rsi + 8
    cmp   SOLVED(%r12), %rax
    ja    better            # solved more: better
    jb    next              # solved fewer: worse
    # Neither jump taken: same number solved. Second key: penalty.
    mov   PENALTY(%rsi), %rax
    cmp   PENALTY(%r12), %rax
    jae   next              # not smaller: keep earlier
                            #   (jae, not ja: on an equal penalty the
                            #   earlier team must stay the best)
better:
    mov   %rsi, %r12        # best = &teams[i]
next:
    inc   %rcx
    jmp   loop

found:
    mov   ID(%r12), %rax    # the winner's letter (in al, the low byte)
    lea   out(%rip), %rsi
    mov   %al, (%rsi)       # replace '?' with the winner's letter
    mov   $1, %rax          # write(1, out, 2): the letter and '\n'
    mov   $1, %rdi
    mov   $2, %rdx
    syscall

    mov   $60, %rax         # exit(0)
    mov   $0, %rdi
    syscall
