public enum NoError {}

public protocol ResultProtocol {

    associatedtype Value
    associatedtype Error

    func iif<T>(success: (Value) throws -> T, failure: (Error) throws -> T) rethrows -> T
}

public extension ResultProtocol {

    var value: Value? {
        return iif(success: { $0 }, failure: { _ in nil })
    }

    var error: Error? {
        return iif(success: { _ in nil }, failure: { $0 })
    }

    func map<T>(_ transform: (Value) throws -> T) rethrows -> Result<T, Error> {
        return try iif(success: { try .success(transform($0)) }, failure: Result.failure)
    }

    func flatMap<T>(_ transform: (Value) throws -> Result<T, Error>) rethrows -> Result<T, Error> {
        return try iif(success: transform, failure: Result.failure)
    }

    func mapError<T>(_ transform: (Error) throws -> T) rethrows -> Result<Value, T> {
        return try iif(success: Result.success, failure: { try .failure(transform($0)) })
    }

    static func `try`(_ body: () throws -> Value) -> Result<Value, Swift.Error> {
        do {
            return try .success(body())
        } catch {
            return .failure(error)
        }
    }
}

public enum Result<Value, Error>: ResultProtocol {

    case success(Value)
    case failure(Error)

    public func iif<T>(success: (Value) throws -> T, failure: (Error) throws -> T) rethrows -> T {
        switch self {
        case let .success(value):
            return try success(value)
        case let .failure(error):
            return try failure(error)
        }
    }

    public init(value: () -> Value?, error: () -> Error) {
        if let value = value() {
            self = .success(value)
        } else {
            self = .failure(error())
        }
    }
}
