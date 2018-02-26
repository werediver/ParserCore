public protocol SomeMatch {

    associatedtype Symbol

    var symbol: Symbol { get }
    var length: Int { get }
}

public struct Match<Symbol>: SomeMatch {

    public let symbol: Symbol
    public let length: Int

    public init<N: SignedInteger>(symbol: Symbol, length: N) {
        self.symbol = symbol
        self.length = Int(length)
    }
}

struct AnyMatch: SomeMatch {

    typealias Symbol = Any

    var symbol: Symbol { return match.symbol }
    var length: Int { return match.length }

    func cast<T>() -> Match<T>? {
        guard T.self == symbolType
        else { return nil }

        return (symbol as? T).map { Match(symbol: $0, length: length) }
    }

    init<T: SomeMatch>(_ match: T) {
        self.match = Match(symbol: match.symbol, length: match.length)
        self.symbolType = T.Symbol.self
    }

    private let match: Match<Any>
    private let symbolType: Any.Type
}

struct AnyMatchResult: SomeEither {

    typealias Left = Mismatch
    typealias Right = AnyMatch

    func iif<T>(right: (Right) throws -> T, left: (Left) throws -> T) rethrows -> T {
        return try result.iif(right: right, left: left)
    }

    func cast<Symbol>() -> Either<Mismatch, Match<Symbol>>? {
        guard Symbol.self == symbolType
        else { return nil }

        return result.iif(right: { $0.cast().map(Either.right) }, left: Either.left)
    }

    init<Result: SomeEither>(_ result: Result) where
        Result.Left == Mismatch,
        Result.Right: SomeMatch
    {
        self.result = result.map { AnyMatch($0) }
        self.symbolType = Result.Right.Symbol.self
    }

    private let result: Either<Mismatch, AnyMatch>
    private let symbolType: Any.Type
}
