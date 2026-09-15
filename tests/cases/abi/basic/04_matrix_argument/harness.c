#include <stdio.h>

#include "f2c.h"

extern int set23_(integer *a);

int main(void)
{
    integer a[6] = {11, 21, 12, 22, 13, 23};
    const integer expected[6] = {11, 21, 12, 22, 13, 99};
    int i;

    (void)set23_(a);
    for (i = 0; i < 6; ++i) {
        if (a[i] != expected[i]) {
            fprintf(stderr,
                    "offset %d: expected %ld, got %ld\n",
                    i,
                    (long)expected[i],
                    (long)a[i]);
            return 1;
        }
    }

    puts("matrix-argument ok");
    return 0;
}
