#include <stdio.h>
int g = 0;

struct return_type {
    int k;
    float f;
    int g;
    double d;
};

// it chopped the r9
return_type bar(int k) {
    return_type r;
    r.k = k;
    r.f = 1.0;
    r.g = 2;
    r.d = 3.0;
    return r;
}


// no_caller_saved
float foo(float a, float b) {
    g = 1;
    return_type r = bar(1);
    printf("g = %d\n", r.k + g);
    return a + b;
}

int main() {
      float a = 1.0;
      float b = 2.0;
      float c = foo(a, b);
      printf("c = %f\n", c);
      return 0;
}