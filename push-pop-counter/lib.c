#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
extern void *__dso_handle __attribute__ ((__visibility__ ("hidden")));

typedef void (*dtor_func) (void *);
extern int __cxa_thread_atexit_impl(dtor_func func, void *obj, void *dso_symbol);

struct Profile {
    uint64_t Spill;
    uint64_t Reload;
    uint64_t Push;
    uint64_t Pop;
};

struct Profile __LLVM_IRPP = {0, 0, 0, 0};
__thread uint64_t __LLVM_IRPP_SpillReg = 0;
__thread uint64_t __LLVM_IRPP_Spill = 0;
__thread uint64_t __LLVM_IRPP_Reload = 0;
__thread uint64_t __LLVM_IRPP_Push = 0;
__thread uint64_t __LLVM_IRPP_Pop = 0;

struct ProfileSpill {
 uint64_t SpillInCallSite;
 uint64_t ReloadInCallSite;
 uint64_t SpillInCallSiteForNCeSR;
 uint64_t ReloadInCallSiteForNCeSR;
 uint64_t SpillInCallSiteForNCrSR;
 uint64_t ReloadInCallSiteForNCrSR;
 uint64_t SpillInPrologue;
 uint64_t ReloadInPrologue;
 uint64_t SpillInPrologueForNCeSR;
 uint64_t ReloadInPrologueForNCeSR;
 uint64_t SpillInPrologueForNCrSR;
 uint64_t ReloadInPrologueForNCrSR;
};

struct ProfileSpill __LLVM_IRPP_SpillRegProfile = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

__thread uint64_t __LLVM_IRPP_SpillInCallSite = 0;
__thread uint64_t __LLVM_IRPP_ReloadInCallSite = 0;
__thread uint64_t __LLVM_IRPP_SpillInCallSiteForNCeSR = 0;
__thread uint64_t __LLVM_IRPP_ReloadInCallSiteForNCeSR = 0;
__thread uint64_t __LLVM_IRPP_SpillInCallSiteForNCrSR = 0;
__thread uint64_t __LLVM_IRPP_ReloadInCallSiteForNCrSR = 0;
__thread uint64_t __LLVM_IRPP_SpillInPrologue = 0;
__thread uint64_t __LLVM_IRPP_ReloadInPrologue = 0;
__thread uint64_t __LLVM_IRPP_SpillInPrologueForNCeSR = 0;
__thread uint64_t __LLVM_IRPP_ReloadInPrologueForNCeSR = 0;
__thread uint64_t __LLVM_IRPP_SpillInPrologueForNCrSR = 0;
__thread uint64_t __LLVM_IRPP_ReloadInPrologueForNCrSR = 0;

__thread uint64_t __LLVM_IRPP_MemoryLoad = 0;
__thread uint64_t __LLVM_IRPP_MemoryStore = 0;

void __LLVM_IRPP_ProfileDtor(void* arg) {
    __LLVM_IRPP.Spill += __LLVM_IRPP_Spill;
    __LLVM_IRPP.Reload += __LLVM_IRPP_Reload;
    __LLVM_IRPP.Push += __LLVM_IRPP_Push;
    __LLVM_IRPP.Pop += __LLVM_IRPP_Pop;

    __LLVM_IRPP_SpillRegProfile.SpillInCallSite += __LLVM_IRPP_SpillInCallSite;
    __LLVM_IRPP_SpillRegProfile.ReloadInCallSite += __LLVM_IRPP_ReloadInCallSite;
    __LLVM_IRPP_SpillRegProfile.SpillInCallSiteForNCeSR += __LLVM_IRPP_SpillInCallSiteForNCeSR;
    __LLVM_IRPP_SpillRegProfile.ReloadInCallSiteForNCeSR += __LLVM_IRPP_ReloadInCallSiteForNCeSR;
    __LLVM_IRPP_SpillRegProfile.SpillInCallSiteForNCrSR += __LLVM_IRPP_SpillInCallSiteForNCrSR;
    __LLVM_IRPP_SpillRegProfile.ReloadInCallSiteForNCrSR += __LLVM_IRPP_ReloadInCallSiteForNCrSR;
    __LLVM_IRPP_SpillRegProfile.SpillInPrologue += __LLVM_IRPP_SpillInPrologue;
    __LLVM_IRPP_SpillRegProfile.ReloadInPrologue += __LLVM_IRPP_ReloadInPrologue;
    __LLVM_IRPP_SpillRegProfile.SpillInPrologueForNCeSR += __LLVM_IRPP_SpillInPrologueForNCeSR;
    __LLVM_IRPP_SpillRegProfile.ReloadInPrologueForNCeSR += __LLVM_IRPP_ReloadInPrologueForNCeSR;
    __LLVM_IRPP_SpillRegProfile.SpillInPrologueForNCrSR += __LLVM_IRPP_SpillInPrologueForNCrSR;
    __LLVM_IRPP_SpillRegProfile.ReloadInPrologueForNCrSR += __LLVM_IRPP_ReloadInPrologueForNCrSR;

}

static void PrintProfile() {
    const char* path = getenv("LLVM_IRPP_PROFILE"); 
    if (path == NULL) path = "regprof3.raw";
    FILE* f = fopen(path, "a");
    fprintf(f, "dynamic spill  (B): %lu\n", __LLVM_IRPP.Spill);
    fprintf(f, "dynamic reload (B): %lu\n", __LLVM_IRPP.Reload);
    fprintf(f, "dynamic push count: %lu\n", __LLVM_IRPP.Push);
    fprintf(f, "dynamic pop  count: %lu\n", __LLVM_IRPP.Pop);

    fprintf(f, "SpillInCallSite: %lu\n", __LLVM_IRPP_SpillRegProfile.SpillInCallSite);
    fprintf(f, "ReloadInCallSite: %lu\n", __LLVM_IRPP_SpillRegProfile.ReloadInCallSite);
    fprintf(f, "SpillInCallSiteForNCeSR: %lu\n", __LLVM_IRPP_SpillRegProfile.SpillInCallSiteForNCeSR);
    fprintf(f, "ReloadInCallSiteForNCeSR: %lu\n", __LLVM_IRPP_SpillRegProfile.ReloadInCallSiteForNCeSR);
    fprintf(f, "SpillInCallSiteForNCrSR: %lu\n", __LLVM_IRPP_SpillRegProfile.SpillInCallSiteForNCrSR);
    fprintf(f, "ReloadInCallSiteForNCrSR: %lu\n", __LLVM_IRPP_SpillRegProfile.ReloadInCallSiteForNCrSR);
    fprintf(f, "SpillInPrologue: %lu\n", __LLVM_IRPP_SpillRegProfile.SpillInPrologue);
    fprintf(f, "ReloadInPrologue: %lu\n", __LLVM_IRPP_SpillRegProfile.ReloadInPrologue);
    fprintf(f, "SpillInPrologueForNCeSR: %lu\n", __LLVM_IRPP_SpillRegProfile.SpillInPrologueForNCeSR);
    fprintf(f, "ReloadInPrologueForNCeSR: %lu\n", __LLVM_IRPP_SpillRegProfile.ReloadInPrologueForNCeSR);
    fprintf(f, "SpillInPrologueForNCrSR: %lu\n", __LLVM_IRPP_SpillRegProfile.SpillInPrologueForNCrSR);
    fprintf(f, "ReloadInPrologueForNCrSR: %lu\n", __LLVM_IRPP_SpillRegProfile.ReloadInPrologueForNCrSR);

    fclose(f);
}

__attribute__ ((constructor)) static void main_thread(void)
{
    __cxa_thread_atexit_impl(__LLVM_IRPP_ProfileDtor, NULL, &__dso_handle);
    atexit(PrintProfile);
}

struct thread_info {
    void *(*start_routine)(void *);
    void *arg;
};

static void* my_start_routine(void* i) {
    struct thread_info* info = (struct thread_info*)i;
    void *(*start_routine)(void *) = info->start_routine;
    void *arg = info->arg;
    free(info);
    __cxa_thread_atexit_impl(__LLVM_IRPP_ProfileDtor, NULL, &__dso_handle);
    return start_routine(arg);
}

int pthread_create(pthread_t *restrict thread,
                    const pthread_attr_t *restrict attr,
                    void *(*start_routine)(void *),
                    void *restrict arg) 
{
    int (*libc_pthread_create)(
        pthread_t *restrict ,
        const pthread_attr_t *restrict,
        void *(*)(void *),
        void *restrict) = dlsym(RTLD_NEXT, "pthread_create");

    struct thread_info* info = (struct thread_info*)malloc(sizeof(struct thread_info));
    info->start_routine = start_routine;
    info->arg = arg;
    return libc_pthread_create(thread, attr, my_start_routine, info);
}


