#include <stdlib.h>
#include <stdio.h>

int g = 0;

// We want to reduce the push/pop and spill code in this function
__attribute__((hot,noinline))
size_t no_callee_saved(size_t k) {
    int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g, n=g, o=g, p=g, q=g, r=g;
    for (int i = 0; i < k; ++i) {
        // registers pressure
        a += 1; b *= a; c += b; d *= c; e += d; 
        f += e; h += f; j += h; l += j; m += l;
        n += m; o += n; p += o; q += p; r += q;
    }
    return a+b+c+d+e+f+h+j+l+m+n+o+p+q+r;
}

__attribute__((cold,noinline))
void func() {
    for (int i = 0; i < 100; ++i)
        g = no_callee_saved(10);
    // printf("%d %d %d %d %d", g,g,g,g,g);
}


int main(int argc, char *argv[]) {
    size_t k = 0;
    k = atoi(argv[1]);
    func();
    return 0;
}
