#include <stdlib.h>

int g = 0;

__attribute__((noinline,no_caller_saved_registers))
void no_ret(int k) {
    g = k;
}

__attribute__((noinline))
int* alloc(size_t size) {
    return (int*) malloc(size*sizeof(int));
}


__attribute__((noinline,no_caller_saved_registers))
int* test(int* ptr) {
    no_ret(*ptr);
    if (g == 0) return ptr+1;
    else return alloc(10);
}


int main(int argc, char** argv) {
    int k = argc;
    test(&k);

    return 0;
}