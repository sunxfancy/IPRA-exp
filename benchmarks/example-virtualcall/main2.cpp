#include <iostream>
#include <cstdlib>
using namespace std;
int g = 0;
struct Shape {
    virtual void draw(int num) = 0;
    void draw2(int num);
};

__attribute__((noinline))
void Shape::draw2(int num) {
    g = num;
}

struct Circle : Shape {
    void draw(int num) override;
};

void Circle::draw(int num) {
    printf("Draw %d %s\n", num, "circles");
}

struct Square : Shape {
    void draw(int num) override;
};

void Square::draw(int num) {
    printf("Draw %d %s\n", num, "squares");
}

__attribute__((noinline))
size_t foo(Shape* s, size_t k) {
    size_t a = k+1;
    size_t b = k-2;
    size_t c = k*3;
    size_t d = k-4;
    size_t e = k+5;
    for (size_t i = 0; i < k; ++i) {
        if (i == k-1) {
            s->draw2(10);
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