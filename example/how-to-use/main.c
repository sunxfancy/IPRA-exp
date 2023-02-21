#include <stdlib.h>
#include <stdio.h>


extern size_t no_callee_saved(size_t k);

int g = 0;

void no_caller_saved() {
    printf("%d %d %d %d %d\n",g,g,g,g,g);
    g=1;
}

void func() {
    for (int i = 0; i < 1000000; ++i)
        no_callee_saved(10);
    // printf("%d %d %d %d %d", g,g,g,g,g);
}

int main(int argc, char *argv[]) {
    size_t k = 0;
    k = atoi(argv[1]);
    func();
    return 0;
}
