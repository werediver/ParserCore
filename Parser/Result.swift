import Foundation

enum Result<V, E: ErrorType>: CustomDebugStringConvertible {

    case Value(V)
    case Error(E)

    var value: V? {
        switch self {
            case let .Value(value):
                return value
            case .Error:
                return nil
        }
    }

    var error: E? {
        switch self {
            case .Value:
                return nil
            case let .Error(error):
                return error
        }
    }

    var debugDescription: String {
        switch self {
            case let .Value(value):
                return "\(value)"
            case let .Error(error):
                return "\(error)"
        }
    }

    @warn_unused_result
    func map<U>(@noescape f: (V) throws -> U) rethrows -> U? {
        return try value.map(f)
    }

    @warn_unused_result
    func flatMap<U>(@noescape f: (V) throws -> U?) rethrows -> U? {
        return try value.flatMap(f)
    }

    @warn_unused_result
    func filter(@noescape predicate: (V) throws -> Bool) rethrows -> V? {
        return try value.map(predicate).flatMap { $0 ? value : nil }
    }

}
