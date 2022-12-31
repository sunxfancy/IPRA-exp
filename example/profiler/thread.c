
#include <stdio.h>
#include <stdint.h>
#include <pthread.h>
#include <stdlib.h>

int g = 0;

__attribute__((cold,noinline))
void no_caller_saved() {
    int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g, n=g, o=g, p=g, q=g, r=g;
    a += 1; b *= a; c += b; d *= c; e += d; 
    f += e; h += f; j += h; l += j; m += l;
    n += m; o += n; p += o; q += p; r += q;
    g = a+b+c+d+e+f+h+j+l+m+n+o+p+q+r;
    // printf("%d %d %d %d %d\n",g,g,g,g,g);
}

// We want to reduce the push/pop and spill code in this function
__attribute__((hot,noinline))
size_t no_callee_saved(size_t k) {
    int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g, n=g, o=g, p=g, q=g, r=g;
    for (int i = 0; i < k; ++i) {
        if (i == g) no_caller_saved(); // cold function
        // registers pressure
        a += 1; b *= a; c += b; d *= c; e += d; 
        f += e; h += f; j += h; l += j; m += l;
        n += m; o += n; p += o; q += p; r += q;
    }
    return a+b+c+d+e+f+h+j+l+m+n+o+p+q+r;
}
__attribute__((cold,noinline))
void* func(void* data) {
    for (int i = 0; i < 1; ++i)
        g = no_callee_saved(10);
    // printf("%d %d %d %d %d", g,g,g,g,g);
    return NULL;
}

pthread_t t1, t2;

int main(int argc, char **argv) {
    // pthread_create(&t1, NULL, func, NULL);
    // pthread_create(&t2, NULL, func, NULL);

    func(NULL);

    // pthread_join(t1, NULL);
    // pthread_join(t2, NULL);

    return 0;
}