#include <stdio.h>

#include "f2c.h"

extern E_f half_(real *value);

int main(void)
{
    real value = 6.f;
    E_f result = half_(&value);

    if (result != (E_f)3.) {
        fprintf(stderr, "expected 3, got %.17g\n", (double)result);
        return 1;
    }

    puts("default-real-function ok");
    return 0;
}
