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

}
