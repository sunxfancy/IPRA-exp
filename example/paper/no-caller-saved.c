#include <stdlib.h>
#include <stdio.h>

int g = 0;

#if defined(_NCSR)
__attribute__ ((cold,no_caller_saved_registers,noinline)) 
#else
__attribute__ ((noinline))
#endif
void no_caller_saved() {
    printf("%d %d %d %d %d", g,g,g,g,g);
}

// We want to reduce the push/pop and spill code in this function
__attribute__((noinline))
size_t func(size_t k) {
    int a=g, b=g, c=g, d=g, e=g;
    for (int i = 0; i < k; ++i) {
        if (k == g) {
            no_caller_saved(); // cold function
        } else {
            // registers pressure
            a += 1; b *= a; c += b+1; d += c+4; e += d-1;
        }
    }
    return a+b+c+d+e;
}



int main(int argc, char *argv[]) {
    size_t k = 0;
    k = atoi(argv[1]);
    size_t ans = 0;
    for (size_t i = 0; i < 100; ++i) {
        ans += func(k);
    }
    printf("ans = %zu\n", ans);    
    return 0;
}
