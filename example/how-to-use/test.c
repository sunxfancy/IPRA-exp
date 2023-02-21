#include <stdlib.h>

extern int g;

extern void no_caller_saved();

// We want to reduce the push/pop and spill code in this function
size_t no_callee_saved(size_t k) {
    int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g; // n=g, o=g, p=g, q=g, r=g;

    // #pragma clang loop unroll(disable)
    for (int i = 0; i < k; ++i) {
        for (int j = 0; j < 10000; ++j) {
        if (i == g) no_caller_saved(); // cold function
        // registers pressure
        a += 1; b *= a; c += b; d *= c; e += d; 
        f += e; h += f; j += h; l += j; m += l;
        // n += m; o += n; p += o; q += p; r += q;
        if (g == 0) no_caller_saved(); // cold function
        if (i == g) break;
        }
    }
    if (g == 0) no_caller_saved(); // cold function
    g = a+b+c+d+e+f+h+j+l+m; //+n+o+p+q+r;
    return g; 
}
