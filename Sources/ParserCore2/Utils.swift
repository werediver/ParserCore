extension String {

    init<T>(optional: T?) {
        if let some = optional {
            self.init(describing: some)
        } else {
            self.init(describing: optional)
        }
    }
}

func id<T>(_ some: T) -> T {
    return some
}

func const<T>(_ some: T) -> (Any) -> T {
    return { _ in some }
}
