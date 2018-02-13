public extension Optional {

    var unwrappedDescription: String {
        return self.map(String.init(describing:)) ?? String(describing: self)
    }
}

public extension Optional where Wrapped == () {

    init(condition: Bool) {
        self = condition ? .some(Void()) : .none
    }
}

public func void(_: Any) {}

public func id<T>(_ some: T) -> T {
    return some
}

public func const<T>(_ some: T) -> (Any) -> T {
    return { _ in some }
}
