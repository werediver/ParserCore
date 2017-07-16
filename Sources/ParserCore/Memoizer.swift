final class Memoizer<Context, Value> {

    typealias ShouldUpdate = (_ cached: Value, _ candidate: Value) -> Bool
    typealias WillReturnFromCache = (Context, Value) -> ()

    private let shouldUpdate: ShouldUpdate
    private let willReturnFromCache: WillReturnFromCache
    private var cache: [AnyHashable: Value] = [:]

    init(shouldUpdate: @escaping ShouldUpdate, willReturnFromCache: @escaping WillReturnFromCache) {
        self.shouldUpdate = shouldUpdate
        self.willReturnFromCache = willReturnFromCache
    }

    func memoize<Key: Hashable>(key: Key, context: Context, _ f: () -> Value) -> Value {
        if let cached = cache[key] {
            willReturnFromCache(context, cached)
            return cached
        } else {
            let candidate = f()
            if  let cached = cache[key],
                !shouldUpdate(cached, candidate)
            {
                willReturnFromCache(context, cached)
                return cached
            }
            cache[key] = candidate
            return candidate
        }
    }
}

extension Memoizer {

    func memoize<Key: Hashable>(key: Key?, context: Context, _ f: () -> Value) -> Value {
        return key.map { memoize(key: $0, context: context, f) } ?? f()
    }
}
