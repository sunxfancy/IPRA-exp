#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>


extern void *__dso_handle __attribute__ ((__visibility__ ("hidden")));
extern void __LLVM_IRPP_ProfileDtor(void* arg);


struct thread_info {
    void *(*start_routine)(void *);
    void *arg;
};

static void* my_start_routine(void* i) {
    struct thread_info* info = (struct thread_info*)i;
    void *(*start_routine)(void *) = info->start_routine;
    void *arg = info->arg;
    free(info);
    printf("register dtor\n");
    __cxa_thread_atexit_impl(__LLVM_IRPP_ProfileDtor, NULL, __dso_handle);
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
    printf("pthread_create called\n");

    struct thread_info* info = (struct thread_info*)malloc(sizeof(struct thread_info));
    info->start_routine = start_routine;
    info->arg = arg;
    return libc_pthread_create(thread, attr, my_start_routine, info);
}

