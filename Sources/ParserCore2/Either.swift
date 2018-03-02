enum Either<Left, Right> {

    case left(Left)
    case right(Right)

    var right: Right? { return iif(right: id, left: const(nil)) }
    var left: Left? { return iif(right: const(nil), left: id) }

    func iif<T>(right f: (Right) -> T, left g: (Left) -> T) -> T {
        switch self {
        case let .right(value):
            return f(value)
        case let .left(value):
            return g(value)
        }
    }
}
