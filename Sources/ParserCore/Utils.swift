public extension Optional {

    var someDescription: String {
        return self.map(String.init(describing:)) ?? String(describing: self)
    }
}

public func void(_: Any) {}

public func id<T>(_ some: T) -> T {
    return some
}

public func const<T>(_ some: T) -> (Any) -> T {
    return { _ in some }
}

public func const<T>(_ some: T) -> (Any, Any) -> T {
    return { _, _ in some }
}
