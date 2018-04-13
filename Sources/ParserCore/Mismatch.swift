public struct Mismatch: Equatable, CustomStringConvertible {

    public let description: String

    public init(description: String) {
        self.description = description
    }
}

public extension Mismatch {

    init(tag: String? = nil, reason: Reason? = nil) {
        let tagDescription = tag.map { "cannot parse \($0)" }
        let reasonDescription = reason.map(String.init(describing:))

        if tagDescription != nil || reasonDescription != nil {
            self.description = [tagDescription, reasonDescription]
                .compactMap(id)
                .joined(separator: ", ")
        } else {
            self.description = "cannot parse this"
        }
    }

    enum Reason: CustomStringConvertible {
        case custom(String)
        case expected(String)

        public var description: String {
            switch self {
            case let .custom(text):
                return text
            case let .expected(text):
                return "expected \(text)"
            }
        }
    }
}
