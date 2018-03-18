public enum Either<Left, Right> {

    case left(Left)
    case right(Right)

    public var right: Right? { return iif(right: id, left: const(nil)) }
    public var left: Left? { return iif(right: const(nil), left: id) }

    public func iif<T>(right f: (Right) -> T, left g: (Left) -> T) -> T {
        switch self {
        case let .right(value):
            return f(value)
        case let .left(value):
            return g(value)
        }
    }

    public func map<T>(_ f: (Right) -> T) -> Either<Left, T> {
        return iif(right: { .right(f($0)) }, left: Either<Left, T>.left)
    }

    public func mapLeft<T>(_ f: (Left) -> T) -> Either<T, Right> {
        return iif(right: Either<T, Right>.right, left: { .left(f($0)) })
    }

    public func flatMap<T>(_ f: (Right) -> Either<Left, T>) -> Either<Left, T> {
        return iif(right: f, left: Either<Left, T>.left)
    }
}
