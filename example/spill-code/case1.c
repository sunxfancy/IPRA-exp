
#include <stdio.h>

int g = 0;

__attribute__((cold,noinline)) 
void no_caller_saved() {
    printf("%d %d %d %d %d\n", g,g,g,g,g);
}

__attribute__((hot,noinline))
int foo(int k) {
    int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g, n=g, o=g, p=g, q=g, r=g;
    for (int i = 0; i < k; ++i) {
        if (i == g) no_caller_saved(); // spill code around cold function 
        // registers pressure
        a += 1; b *= a; c += b; d *= c; e += d; 
        f += e; h += f; j += h; l += j; m += l;
        n += m; o += n; p += o; q += p; r += q;
    }
    g = a+b+c+d+e+f+h+j+l+m+n+o+p+q+r;
    return g; 
}

int main() {
    foo(10);
    foo(15);
    return 0;
}
