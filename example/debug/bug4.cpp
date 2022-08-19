#include <stdio.h>

#ifdef NCSR
#define NO_CALLER_SAVED no_caller_saved_registers
#else
#define NO_CALLER_SAVED 
#endif

int g = 0;

struct A {
    A* data[5];

    A() { data[0] = nullptr; }

    __attribute__((noinline, NO_CALLER_SAVED))
    A* get(unsigned i) const;
};

__attribute__((noinline))
void test(int p, int k) {
    g = k;
}

__attribute__((noinline, NO_CALLER_SAVED))
A* A::get(unsigned i) const { 
    test(0, 999999999999);
    g = 0; return data[i]; 
}

__attribute__((noinline))
bool main_func(A* a, unsigned k) {
    int arr[10]; arr[0] = 1;
    for (unsigned i = 0; i < k; ++i) {
        if (a->get(i) == 0 && arr[i]) {
            printf("i = %d\n", i);
            return true;
        }
    }
    return false;
}


int main(int argc, char* argv[0]) {
    int k = argc;
    
    A* a = new A();
    bool t = main_func(a, k);
    return 0;
}


