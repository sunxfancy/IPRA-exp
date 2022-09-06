#include <stdlib.h>
#include <stdio.h>

int g = 0;

__attribute__ ((noinline)) 
void cold_callee(size_t a, size_t b, size_t c, size_t d, size_t e) {
    g = a+b*c-d*e;
}


__attribute__((noinline))
size_t func(size_t k) {
    size_t a = k+1;
    size_t b = k-2;
    size_t c = k*3;
    size_t d = k-4;
    size_t e = k+5;

    for (size_t i = 0; i < k; ++i) {
        if (i == 1000) {
            cold_callee(a,b,c,d,e);
        } else {
            a += 1;
            b += 2;
            c += b+1;
            d += 4;
            e += d-1;
        }
    }
    return a+b+c+d+e;
}

__attribute__ ((noinline)) 
void hot_callee(size_t a, size_t b, size_t c, size_t d, size_t e) {
    g = a+b*c-d*e;
}


__attribute__((noinline))
size_t func2(size_t k) {
    size_t a = k+1;
    size_t b = k-2;
    size_t c = k*3;
    size_t d = k-4;
    size_t e = k+5;

    for (size_t i = 0; i < k; ++i) {
        if (i == 1000) {
            hot_callee(a,b,c,d,e);
        } else {
            a += 1;
            b += 2;
            c += b+1;
            d += 4;
            e += d-1;
        }
    }
    return a+b+c+d+e;
}


typedef void (*func_ptr)(size_t a, size_t b, size_t c, size_t d, size_t e);

__attribute__((noinline))
size_t func3(size_t k, func_ptr callee) {
    size_t a = k+1;
    size_t b = k-2;
    size_t c = k*3;
    size_t d = k-4;
    size_t e = k+5;

    for (size_t i = 0; i < k; ++i) {
        if (i % 2 == 0) {
            callee(a,b,c,d,e);
        } else {
            a += 1;
            b += 2;
            c += b+1;
            d += 4;
            e += d-1;
        }
    }
    return a+b+c+d+e;
}



int main(int argc, char *argv[]) {
    size_t k = 0;
    k = atoi(argv[1]);
    size_t ans = 0;
    for (size_t i = 0; i < 100; ++i) {
        ans += func(k);
    }
    for (size_t i = 0; i < 100; ++i) {
        ans += func2(k);
    }
    for (int i = 0; i < 1000; ++i) {
        hot_callee(1,2,3,4,5);
    }

    for (size_t i = 0; i < 100; ++i) {
        ans += func3(k, hot_callee);
    }

    func3(2, cold_callee);

    printf("ans = %zu\n", ans);    
    return 0;
}
