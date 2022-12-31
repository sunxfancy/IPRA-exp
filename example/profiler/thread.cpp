#include <stdio.h>
#include <stdint.h>
#include <pthread.h>

struct LLVM_IRPP_Counts {
    uint64_t Spill = 0;
    uint64_t Reload = 0;
    uint64_t Push = 0;
    uint64_t Pop = 0;

    ~LLVM_IRPP_Counts();
};

struct LLVM_IRPP_Counts __LLVM_IRPP_Counts;
thread_local LLVM_IRPP_Counts __LLVM_IRPP_TLCounts;

LLVM_IRPP_Counts::~LLVM_IRPP_Counts() {
    if (this == &__LLVM_IRPP_Counts) {
        FILE* f = fopen("default.irpp", "w");
        fprintf(f, "%lu %lu %lu %lu\n", Spill, Reload, Push, Pop);
        fclose(f);
        printf("default.irpp exit\n");
        return;
    }
    static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_lock(&mutex);
    __LLVM_IRPP_Counts.Spill += Spill;
    __LLVM_IRPP_Counts.Reload += Reload;
    __LLVM_IRPP_Counts.Push += Push;
    __LLVM_IRPP_Counts.Pop += Pop;
    pthread_mutex_unlock(&mutex);
    pthread_t a = pthread_self();
    printf("pthread %lu exit\n", a);
}

// int g = 0;

// __attribute__((cold,noinline))
// void no_caller_saved() {
//     printf("%d %d %d %d %d\n",g,g,g,g,g);
// }

// // We want to reduce the push/pop and spill code in this function
// __attribute__((hot,noinline))
// size_t no_callee_saved(size_t k) {
//     int a=g, b=g, c=g, d=g, e=g, f=g, h=g, j=g, l=g, m=g, n=g, o=g, p=g, q=g, r=g;
//     for (int i = 0; i < k; ++i) {
//         if (i == g) no_caller_saved(); // cold function
//         // registers pressure
//         a += 1; b *= a; c += b; d *= c; e += d; 
//         f += e; h += f; j += h; l += j; m += l;
//         n += m; o += n; p += o; q += p; r += q;
//     }
//     return a+b+c+d+e+f+h+j+l+m+n+o+p+q+r;
// }

__attribute__((cold,noinline))
void* func(void*) {
    // for (int i = 0; i < 100; ++i)
    //     g = no_callee_saved(10);
    // printf("%d %d %d %d %d", g,g,g,g,g);

    __LLVM_IRPP_TLCounts.Spill = __LLVM_IRPP_TLCounts.Spill + 5;
    return NULL;
}

pthread_t t1, t2;

int main(int argc, char **argv) {
    pthread_create(&t1, NULL, func, NULL);
    pthread_create(&t2, NULL, func, NULL);

    __LLVM_IRPP_TLCounts.Spill = __LLVM_IRPP_TLCounts.Spill + 5;

    pthread_join(t1, NULL);
    pthread_join(t2, NULL);
    return 0;
}