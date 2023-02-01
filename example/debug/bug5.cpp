#include <stdio.h>
#include <stdlib.h>

int g;

int no_callee_saved(int k) {
    int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g; // n=g, o=g, p=g, q=g, r=g;
    for (int i = 0; i < k; ++i) {
        // registers pressure
        a += 1; b *= a; c += b; d *= c; e += d; 
        f += e; h += f; j += h; l += j; m += l;
        // n += m; o += n; p += o; q += p; r += q;
    }
    g = a+b+c+d+e+f+h+j+l+m; //+n+o+p+q+r;
    return g; 

    return 0;
}


int main(int argc, char* argv[0]) {
    int k = atoi(argv[1]);
    int a=g, b=g, c=g, d=g, f=g, h=g, j=g, l=g, m=g; 
    for (int i = 0; i < k; ++i) {
        // registers pressure
        a += 1; b *= a; c += b; d *= c; f += d; h += f; j +=d - h; l += j * a; m += l - 2;
        g += no_callee_saved(k);
    }
    g -= a+b+c+d+f+h+j+l+m;
    return 0;
}
