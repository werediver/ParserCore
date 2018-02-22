#include "include/thread_time.h"
#include <mach/mach_init.h>
#include <mach/thread_act.h>
#include <mach/thread_info.h>

int64_t time_value_to_us(time_value_t const t) {
    return (int64_t)t.seconds * 1000000 + t.microseconds;
}

thread_time_t thread_time() {
    thread_basic_info_data_t basic_info;
    mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
    kern_return_t const result = thread_info(mach_thread_self(), THREAD_BASIC_INFO, (thread_info_t)&basic_info, &count);
    if (result == KERN_SUCCESS) {
        return (thread_time_t){
            .user_time_us   = time_value_to_us(basic_info.user_time),
            .system_time_us = time_value_to_us(basic_info.system_time)
        };
    } else {
        return (thread_time_t){-1, -1};
    }
}

thread_time_t thread_time_sub(thread_time_t const a, thread_time_t const b) {
    return (thread_time_t){
        .user_time_us   = a.user_time_us   - b.user_time_us,
        .system_time_us = a.system_time_us - b.system_time_us
    };
}
