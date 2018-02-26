public enum NoError {}

public protocol SomeEither {

    associatedtype Left
    associatedtype Right

    func iif<T>(right: (Right) throws -> T, left: (Left) throws -> T) rethrows -> T
}

public extension SomeEither {

    var left: Left? { return iif(right: const(nil), left: id) }

    var right: Right? { return iif(right: id, left: const(nil)) }

    func map<T>(_ transform: (Right) throws -> T) rethrows -> Either<Left, T> {
        return try iif(right: { try .right(transform($0)) }, left: Either.left)
    }

    func flatMap<T>(_ transform: (Right) throws -> Either<Left, T>) rethrows -> Either<Left, T> {
        return try iif(right: transform, left: Either.left)
    }

    func mapLeft<T>(_ transform: (Left) throws -> T) rethrows -> Either<T, Right> {
        return try iif(right: Either.right, left: { try .left(transform($0)) })
    }

    static func `try`(_ body: () throws -> Right) -> Either<Error, Right> {
        do {
            return try .right(body())
        } catch {
            return .left(error)
        }
    }
}

public enum Either<Left, Right>: SomeEither {

    case left(Left)
    case right(Right)

    public func iif<T>(right: (Right) throws -> T, left: (Left) throws -> T) rethrows -> T {
        switch self {
        case let .left(error):
            return try left(error)
        case let .right(value):
            return try right(value)
        }
    }

    public init(value: () -> Right?, error: () -> Left) {
        if let value = value() {
            self = .right(value)
        } else {
            self = .left(error())
        }
    }
}
