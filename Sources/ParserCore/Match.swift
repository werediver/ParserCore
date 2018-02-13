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

struct AnyMatchResult: EitherRepresenting {

    typealias Right = AnyMatch
    typealias Left = Mismatch

    func iif<T>(right: (Right) throws -> T, left: (Left) throws -> T) rethrows -> T {
        return try result.iif(right: right, left: left)
    }

    func cast<Symbol>() -> Either<Mismatch, Match<Symbol>>? {
        return Optional(condition: Symbol.self == symbolType).flatMap {
            result.iif(right: { $0.cast().map(Either.right) }, left: Either.left)
        }
    }

    init<Result: EitherRepresenting>(_ result: Result) where
        Result.Right: MatchRepresenting,
        Result.Left == Mismatch
    {
        self.result = result.map { AnyMatch($0) }
        self.symbolType = Result.Right.Symbol.self
    }

    private let result: Either<Mismatch, AnyMatch>
    private let symbolType: Any.Type
}
