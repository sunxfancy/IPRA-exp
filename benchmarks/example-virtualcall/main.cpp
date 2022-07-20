#include <iostream>
#include <cstdlib>
using namespace std;

struct Shape {
    virtual void draw(int num) = 0;
};

struct Circle : Shape {
    virtual void draw(int num) override {
        printf("Draw %d %s\n", num, "circles");
    }
};

struct Square : Shape {
    virtual void draw(int num) override {
        printf("Draw %d %s\n", num, "squares");
    }
};

__attribute__((noinline))
size_t foo(Shape* s, size_t k) {
    size_t a = k+1;
    size_t b = k-2;
    size_t c = k*3;
    size_t d = k-4;
    size_t e = k+5;
    for (size_t i = 0; i < k; ++i) {
        if (i == k-1) {
            s->draw(10);
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

int main(int argc, char** argv) {
    size_t k = 0;
    k = atoi(argv[1]);
    Shape* s = new Circle();
    printf("ans = %zu", foo(s, k));    
    return 0;
}