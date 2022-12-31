#include <stdio.h>
#include <stdint.h>
#include <pthread.h>
#include "cxxabi.h"

extern "C" {
__thread uint64_t __LLVM_IRPP_SpillReg = 0;
__thread uint64_t __LLVM_IRPP_Spill = 0;
__thread uint64_t __LLVM_IRPP_Reload = 0;
__thread uint64_t __LLVM_IRPP_Push = 0;
__thread uint64_t __LLVM_IRPP_Pop = 0;
}


void __LLVM_IRPP_Dtor(void *obj) {
    FILE* f = fopen("default.irpp", "w");
    fprintf(f, "%lu %lu %lu %lu\n", __LLVM_IRPP_Spill, __LLVM_IRPP_Reload, __LLVM_IRPP_Push, __LLVM_IRPP_Pop);
    fclose(f);
    printf("default.irpp exit\n");
}

struct LLVM_IRPP_HOOK {
    LLVM_IRPP_HOOK() {
        __cxxabiv1::__cxa_thread_atexit(__LLVM_IRPP_Dtor, NULL, NULL);
    }
};
static LLVM_IRPP_HOOK __LLVM_IRPP_HOOK;
