/*
 * C calling assembly: the functions below are written in 18.funcs.s.
 *
 * Build:  gcc -o 18.c_calls_asm 18.main.c 18.funcs.s
 */
#include <stdio.h>

long sum_array(const long *a, long n);
void str_upper(char *s);

int main(void)
{
    long nums[] = {3, -1, 4, 1, -5, 9, 2, 6};
    long n = sizeof nums / sizeof nums[0];
    printf("sum_array = %ld\n", sum_array(nums, n));

    char word[] = "Hello, Assembly!";
    str_upper(word);
    printf("str_upper -> %s\n", word);
    return 0;
}
