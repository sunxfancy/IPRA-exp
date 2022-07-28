#include <stdlib.h>

int global = 0;
__attribute__((noinline))
size_t report(size_t a) {
    static size_t first = 1;
    if (first == 1) {
        first = 0;
        global = a;
    }
    return 0;
}
