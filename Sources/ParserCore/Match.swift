public protocol MatchRepresenting {

    associatedtype Symbol

    var symbol: Symbol { get }
    var length: Int { get }
}

public struct Match<Symbol>: MatchRepresenting {

    public let symbol: Symbol
    public let length: Int

    public init<N: SignedInteger>(symbol: Symbol, length: N) {
        self.symbol = symbol
        self.length = Int(length)
    }
}

struct AnyMatch: MatchRepresenting {

    typealias Symbol = Any

    var symbol: Symbol { return match.symbol }
    var length: Int { return match.length }

    func cast<T>() -> Match<T>? {
        return Optional(condition: T.self == symbolType).flatMap {
            (symbol as? T).map { Match(symbol: $0, length: length) }
        }
    }

    init<T: MatchRepresenting>(_ match: T) {
        self.match = Match(symbol: match.symbol, length: match.length)
        self.symbolType = T.Symbol.self
    }

    private let match: Match<Any>
    private let symbolType: Any.Type
}

struct AnyMatchResult: ResultRepresenting {

    typealias Value = AnyMatch
    typealias Error = Mismatch

    func iif<T>(success: (Value) throws -> T, failure: (Error) throws -> T) rethrows -> T {
        return try result.iif(success: success, failure: failure)
    }

    func cast<Symbol>() -> Result<Match<Symbol>, Mismatch>? {
        return Optional(condition: Symbol.self == symbolType).flatMap {
            result.iif(success: { $0.cast().map(Result.success) }, failure: Result.failure)
        }
    }

    init<Result: ResultRepresenting>(_ result: Result) where
        Result.Value: MatchRepresenting,
        Result.Error == Mismatch
    {
        self.result = result.map { AnyMatch($0) }
        self.symbolType = Result.Value.Symbol.self
    }

    private let result: Result<AnyMatch, Mismatch>
    private let symbolType: Any.Type
}
