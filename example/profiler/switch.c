#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char** argv) {
    switch (argc)
    {
    case 1:
        printf("1\n");
    case 2:
        printf("2\n");
        break;
    case 3:
        printf("3\n");
        break;
    default:
        break;
    }
    return 0;
}