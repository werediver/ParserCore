public enum CountLimit {
    case atLeast(Int)
    case atMost(Int)
    case times(Int, Int)

    public static func exactly(_ count: Int) -> CountLimit {
        return .times(count, count)
    }

    public func extends(past count: Int) -> Bool {
        switch self {
        case .atLeast:
            return true
        case let .atMost(atMost):
            return count < atMost
        case let .times(_, atMost):
            return count < atMost
        }
    }

    public func contains(_ count: Int) -> Bool {
        switch self {
        case let .atLeast(atLeast):
            return atLeast <= count
        case let .atMost(atMost):
            return count <= atMost
        case let .times(atLeast, atMost):
            return atLeast <= count
                && count <= atMost
        }
    }
}
