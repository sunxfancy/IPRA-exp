#include <stdio.h>

#ifdef NCSR
#define NO_CALLER_SAVED no_caller_saved_registers
#else
#define NO_CALLER_SAVED 
#endif

int g = 0;

struct A {
    int k;
    void *p, *q;
};

__attribute__((noinline,NO_CALLER_SAVED))
A foo() {
    g = 0;
    A data;
    data.k = 10;
    return data;
}

__attribute__((noinline))
int hh(int k) { return k+10; }


int main(int argc, char* argv[0]) {
    int k = argc;
    k = k*2;
    int p = 0;
    p = hh(k);   
    foo();
    printf("%d\n", p);
    return 0;
}

void test() {
    A g = foo();
    printf("g.k", g.k);
}

