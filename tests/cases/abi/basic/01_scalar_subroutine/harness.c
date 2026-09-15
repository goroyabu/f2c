#include <stdio.h>

#include "f2c.h"

extern int incr_(integer *value);

int main(void)
{
    integer value = 7;

    (void)incr_(&value);
    if (value != 12) {
        fprintf(stderr, "expected 12, got %ld\n", (long)value);
        return 1;
    }

    puts("scalar-subroutine ok");
    return 0;
}
