public protocol TerminalMatchProtocol {

    associatedtype Symbol

    var symbol: Symbol { get }
    var length: Int { get }
}

// TODO: Consider renaming to `Match`.
public struct TerminalMatch<Symbol>: TerminalMatchProtocol {

    public let symbol: Symbol
    public let length: Int

    public init<N: SignedInteger>(symbol: Symbol, length: N) {
        self.symbol = symbol
        self.length = Int(length)
    }
}

struct AnyTerminalMatch: TerminalMatchProtocol {

    typealias Symbol = Any

    var symbol: Symbol { return match.symbol }
    var length: Int { return match.length }

    func cast<T>() -> TerminalMatch<T>? {
        return Optional(condition: T.self == symbolType).flatMap {
            (symbol as? T).map { TerminalMatch(symbol: $0, length: length) }
        }
    }

    init<Match: TerminalMatchProtocol>(_ match: Match) {
        self.match = TerminalMatch(symbol: match.symbol, length: match.length)
        self.symbolType = Match.Symbol.self
    }

    private let match: TerminalMatch<Any>
    private let symbolType: Any.Type
}

struct AnyTerminalMatchResult: ResultProtocol {

    typealias Value = AnyTerminalMatch
    typealias Error = Mismatch

    func iif<T>(success: (Value) throws -> T, failure: (Error) throws -> T) rethrows -> T {
        return try result.iif(success: success, failure: failure)
    }

    func cast<Symbol>() -> Result<TerminalMatch<Symbol>, Mismatch>? {
        return Optional(condition: Symbol.self == symbolType).flatMap {
            result.iif(success: { $0.cast().map(Result.success) }, failure: Result.failure)
        }
    }

    init<Result: ResultProtocol>(_ result: Result) where
        Result.Value: TerminalMatchProtocol,
        Result.Error == Mismatch
    {
        self.result = result.map { AnyTerminalMatch($0) }
        self.symbolType = Result.Value.Symbol.self
    }

    private let result: Result<AnyTerminalMatch, Mismatch>
    private let symbolType: Any.Type
}
