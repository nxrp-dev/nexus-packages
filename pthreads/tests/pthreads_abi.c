/* Copyright (c) 2026 Kevin Collins. SPDX-License-Identifier: MPL-2.0-no-copyleft-exception */
#define _GNU_SOURCE
#include <pthread.h>
#include <semaphore.h>
#include <signal.h>
#include <stddef.h>
#include <dlfcn.h>
int nx_has_linuxthreads(void) {
    return dlsym(RTLD_DEFAULT, "pthread_kill_other_threads_np") != NULL ||
           dlsym(RTLD_DEFAULT, "__pthread_initialize") != NULL;
}
int nx_mutex_fast(void) { return PTHREAD_MUTEX_FAST_NP; }
int nx_rwlock_default(void) { return PTHREAD_RWLOCK_DEFAULT_NP; }
size_t nx_pthread_size(unsigned int index) {
    const size_t sizes[] = {
        sizeof(pthread_t), sizeof(pthread_attr_t), sizeof(pthread_mutex_t),
        sizeof(pthread_mutexattr_t), sizeof(pthread_cond_t), sizeof(pthread_condattr_t),
        sizeof(pthread_rwlock_t), sizeof(pthread_rwlockattr_t), sizeof(pthread_once_t),
        sizeof(pthread_key_t), sizeof(pthread_barrier_t), sizeof(pthread_barrierattr_t),
        sizeof(sem_t), sizeof(sigset_t)
    };
    return sizes[index];
}
