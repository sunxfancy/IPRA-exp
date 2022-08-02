// Type your code here, or load an example.
#include <iostream>

struct Iter {
    int* p = nullptr;
};

class Test {
public:
    Test(int* d, Iter k) : data(d) {p[1] = k;}
    int k;
    int* data;
    Iter p[2];
    
    __attribute__ ((no_caller_saved_registers, noinline))
    Test compute();

    __attribute__ ((noinline))
    void large(int a, int b, int c, int d, int e, int f);
};

__attribute__ ((no_caller_saved_registers,noinline))
static void call_large_func() {
    printf("hhh\n");
}

__attribute__ ((no_caller_saved_registers, noinline)) 
Test Test::compute() {
    if (data) {
        call_large_func();
    }
    return Test{data+1, Iter{data+2}};
}

void Test::large(int a, int b, int c, int d, int e, int f) {
    printf("int b, int c, int d, int e, int f = %d %d %d %d %d %d", a, b, c, d, e, f);
}


int main() {
    int* k = new int[20];
    Test t(k, Iter{});
    std::cin >> k[0];
    k[0] += 1;
    Test t2 = t.compute();
    t2.large(0, 1, k[0], 3, 4, 5);
    printf("t2 = %d \n", *t2.data);

    return 0;
}
