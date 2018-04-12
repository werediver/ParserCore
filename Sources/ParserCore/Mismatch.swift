public struct Mismatch: Equatable {

    let tag: String?
    let reason: Reason?

    var isEmpty: Bool { return tag == nil && reason == nil }

    public init(tag: String? = nil, reason: Reason? = nil) {
        if case let (nil, .got(mismatch)?) = (tag, reason) {
            self = mismatch
        } else {
            self.tag = tag
            self.reason = reason
        }
    }

    public enum Reason: Equatable {

        case custom(String)
        case expected(String)
        indirect case got(Mismatch)
    }
}

extension Mismatch: CustomStringConvertible {

    public var description: String {
        var tagDescription: String? { return tag.map { "cannot parse \($0)" } }
        var reasonDescription: String? {
            switch reason {
            case let .custom(text)?:
                return text
            case let .expected(expectation)?:
                return "expected \(expectation)"
            case let .got(mismatch)? where !mismatch.isEmpty:
                return "because \(mismatch)"
            case nil, .got(_)?:
                return nil
            }
        }

        if !isEmpty {
            return [tagDescription, reasonDescription]
                .compactMap(id)
                .joined(separator: ", ")
        } else {
            return "cannot parse this"
        }
    }
}
