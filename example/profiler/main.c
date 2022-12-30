#include <stdio.h>
#include <stdint.h>

extern uint64_t __LLVM_IRPP_SpillReg = 0;
extern uint64_t __LLVM_IRPP_Spill = 0;
extern uint64_t __LLVM_IRPP_Reload = 0;
extern uint64_t __LLVM_IRPP_Push = 0;
extern uint64_t __LLVM_IRPP_Pop = 0;

int g = 0;

__attribute__((cold,noinline))
void no_caller_saved() {
    printf("%d %d %d %d %d\n",g,g,g,g,g);
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
void func() {
    for (int i = 0; i < 100; ++i)
        g = no_callee_saved(10);
    // printf("%d %d %d %d %d", g,g,g,g,g);
}


int main(int argc, char **argv) {
    func();

    printf("spill = %lu reload = %lu \n", __LLVM_IRPP_Spill, __LLVM_IRPP_Reload);
    printf("push = %lu pop = %lu \n", __LLVM_IRPP_Push, __LLVM_IRPP_Pop);
    return 0;
}