public struct Mismatch: Equatable {

    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }
}

extension Mismatch: CustomStringConvertible {

    public var description: String { return reason }
}

public extension Mismatch {

    init() {
        self.init(reason: "cannot parse this")
    }

    static func expected(_ target: String) -> Mismatch {
        return Mismatch(reason: "expected \(target)")
    }

    static func cannotConvert(_ some: String, to target: String) -> Mismatch {
        return Mismatch(reason: "cannot convert \(some) to \(target)")
    }
}
