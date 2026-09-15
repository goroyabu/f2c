#include <stdio.h>

#include "f2c.h"

extern integer twice_(integer *value);

int main(void)
{
    integer value = 7;
    integer result = twice_(&value);

    if (result != 14) {
        fprintf(stderr, "expected 14, got %ld\n", (long)result);
        return 1;
    }

    puts("integer-function ok");
    return 0;
}
