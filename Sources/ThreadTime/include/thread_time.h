#ifndef thread_time_h
#define thread_time_h

#include <stdint.h>

typedef struct thread_time {
    int64_t user_time_us;
    int64_t system_time_us;
} thread_time_t;

thread_time_t thread_time();
thread_time_t thread_time_sub(thread_time_t const a, thread_time_t const b);

#endif /* thread_time_h */
