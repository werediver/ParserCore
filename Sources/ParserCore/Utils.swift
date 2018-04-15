extension String {

    var nonEmpty: String? { return isEmpty ? nil : self }
}

func describe<T>(_ some: T?) -> String {
    return some.map(String.init(describing:)) ?? String(describing: some)
}

public func id<T>(_ some: T) -> T {
    return some
}

public func const<T>(_ some: T) -> (Any) -> T {
    return { _ in some }
}

public func const<T>(_ some: T) -> (Any, Any) -> T {
    return { _, _ in some }
}

extension Collection {

    subscript(safe index: Index) -> Element? {
        return (startIndex ..< endIndex).contains(index) ? self[index] : nil
    }
}
