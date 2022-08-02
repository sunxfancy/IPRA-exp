// Type your code here, or load an example.
#include <stdlib.h>
#include <stdio.h>

int g = 0;
__attribute__ ((noinline)) 
void simple() {
    printf("a = %d, b = %d, c = %d, d = %d, e = %d\n", g+1, g+2, g+3, g+4, g+5);
}

__attribute__ ((no_caller_saved_registers, noinline)) 
void no_caller_saved(size_t a) {
    g = a;
    simple();
}


__attribute__((noinline))
size_t func(size_t k) {
    size_t a = k+1;
    size_t b = k-2;
    size_t c = k*3;
    size_t d = k-4;
    size_t e = k+5;

    for (size_t i = 0; i < k; ++i) {
        if (i == k-1) {
            no_caller_saved(a);
        } else {
            a += 1;
            b += 2;
            c += b+1;
            d += 4;
            e += d-1;
        }
    }
    return a+b+c+d+e;
}



int main(int argc, char *argv[]) {
    size_t k = 0;
    k = 10;
    size_t ans = 0;
    for (size_t i = 0; i < 100; ++i) {
        ans += func(k);
    }
    printf("ans = %zu\n", ans);    
    return 0;
}
