# Build every program in this directory with as and ld (no gcc).
SRC  := $(wildcard *.s)
PROG := $(SRC:.s=)

all: $(PROG)

%: %.s
	as -g -o $@.o $<
	ld -o $@ $@.o

clean:
	rm -f *.o $(PROG)

.PHONY: all clean
