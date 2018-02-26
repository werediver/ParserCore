final class DepthLimiter {

    private var depthMap = [AnyHashable: Int]()

    func limitDepth<Key: Hashable, T>(key: Key, limit: Int, _ f: () -> T) -> T? {
        let depth = depthMap[key] ?? 0
        if depth > limit {
            return nil
        } else {
            depthMap[key] = depth + 1
            defer { depthMap[key] = depth > 0 ? depth : nil }
            return f()
        }
    }
}

extension DepthLimiter {

    func limitDepth<Key: Hashable, T>(key: Key?, limit: Int, _ f: () -> T) -> T? {
        return key.map { limitDepth(key: $0, limit: limit, f) } ?? f()
    }
}
