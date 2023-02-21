#include <string>
#include <stdio.h>

int main(int argc, char **argv) {
    std::string s = "hello ";
    if (argc > 1) {
        s += argv[1];
        printf("%s\n", s.c_str());
    }
    return 0;
}