import ThreadTime
import struct Foundation.TimeInterval

func benchmark(times: Int = 1, _ body: () -> Void) -> (avgUserTime: TimeInterval, avgSysTime: TimeInterval) {
    let start = thread_time()
    for _ in 0 ..< times {
        body()
    }
    let end = thread_time()
    let duration = thread_time_sub(end, start)
    return (
        avgUserTime: timeInterval(us: duration.user_time_us)  / Double(times),
        avgSysTime: timeInterval(us: duration.system_time_us) / Double(times)
    )
}

private func timeInterval(us: Int64) -> TimeInterval {
    return TimeInterval(Double(us) / 1000_000)
}
