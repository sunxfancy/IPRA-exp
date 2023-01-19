
#include <stdio.h>

int g = 0;


__attribute__((hot,noinline))
int foo(int k) {
    int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g, n=g, o=g, p=g, q=g, r=g;
    for (int i = 0; i < k; ++i) {
        // registers pressure
        a += 1; b *= a; c += b; d *= c; e += d; 
        f += e; h += f; j += h; l += j; m += l;
        n += m; o += n; p += o; q += p; r += q;
    }
    g = a+b+c+d+e+f+h+j+l+m+n+o+p+q+r;
    return g; 
}

int t = 0;

int main() {
    int p = 0;
    for (int i = 0; i < 1000; ++i) {
        p += foo(10);
        t += p * foo(15);
    }
    return 0;
}
