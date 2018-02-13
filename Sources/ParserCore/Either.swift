public enum NoError {}

public protocol EitherRepresenting {

    associatedtype Left
    associatedtype Right

    func iif<T>(right: (Right) throws -> T, left: (Left) throws -> T) rethrows -> T
}

public extension EitherRepresenting {

    var value: Right? {
        return iif(right: { $0 }, left: { _ in nil })
    }

    var error: Left? {
        return iif(right: { _ in nil }, left: { $0 })
    }

    func map<T>(_ transform: (Right) throws -> T) rethrows -> Either<Left, T> {
        return try iif(right: { try .right(transform($0)) }, left: Either.left)
    }

    func flatMap<T>(_ transform: (Right) throws -> Either<Left, T>) rethrows -> Either<Left, T> {
        return try iif(right: transform, left: Either.left)
    }

    func mapError<T>(_ transform: (Left) throws -> T) rethrows -> Either<T, Right> {
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

public enum Either<Left, Right>: EitherRepresenting {

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
