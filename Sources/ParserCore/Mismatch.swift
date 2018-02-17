public struct Mismatch {

    public let message: String?

    public init(message: String? = nil) {
        self.message = message
    }
}

extension Mismatch: CustomStringConvertible {
    public var description: String { return message ?? "No match" }
}

public extension Mismatch {

    enum Expectation: CustomStringConvertible {
        case expectation(Any)
        case serializedExpectation(String)

        public var description: String {
            switch self {
            case let .expectation(some):
                return String(reflecting: some)
            case let .serializedExpectation(some):
                return String(describing: some)
            }
        }
    }

    init(tag: String?, _ expectation: Expectation? = nil) {
        switch (tag, expectation) {
        case let (.some(tag), .some(expectation)):
            self.message = "Cannot parse \(tag): expected \(expectation)"
        case let (.some(tag), nil):
            self.message = "Cannot parse \(tag)"
        case let (nil, .some(expectation)):
            self.message = "Expected \(expectation)"
        case (nil, nil):
            self.message = nil
        }
    }
}