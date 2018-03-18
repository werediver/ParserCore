public protocol SomeParser {

    associatedtype Core: SomeCore
    associatedtype Symbol

    typealias Match = Either<Mismatch, Symbol>

    var tag: String? { get }

    func parse(core: Core) -> Match
}

public struct GenericParser<_Core: SomeCore, _Symbol>: SomeParser {

    public typealias Core = _Core
    public typealias Symbol = _Symbol

    public typealias Body = (GenericParser, Core) -> Match

    private let body: Body

    public let tag: String?

    public init(tag: String? = nil, _ body: @escaping Body) {
        self.tag = tag
        self.body = body
    }

    public func parse(core: Core) -> Match {
        return body(self, core)
    }
}

public extension GenericParser {

    init<Parser: SomeParser>(tag: String? = nil, _ body: @escaping (_ this: GenericParser, Core) -> Parser) where
        Parser.Core == Core,
        Parser.Symbol == Symbol
    {
        self.init(tag: tag) { this, core in core.parse(body(this, core)) }
    }
}

public extension SomeParser {

    func map<T>(tag: String? = nil, _ f: @escaping (Symbol) -> T) -> GenericParser<Core, T> {
        return GenericParser<Core, T>(tag: tag) { _, core in
            core.parse(self)
                .map(f)
        }
    }

    func attemptMap<T>(tag: String? = nil, _ f: @escaping (Symbol) -> Either<Mismatch, T>) -> GenericParser<Core, T> {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .flatMap(f)
        }
    }

    func mapError(tag: String? = nil, _ f: @escaping (Mismatch) -> Mismatch) -> GenericParser<Core, Symbol> {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .mapLeft(f)
        }
    }

    public func flatMap<Parser: SomeParser>(tag: String? = nil, _ f: @escaping (Symbol) -> Parser) -> GenericParser<Core, Parser.Symbol> where
        Parser.Core == Core
    {
        return GenericParser<Core, Parser.Symbol>(tag: tag) { _, core in
            core.parse(self)
                .iif(
                    right: { symbol in core.parse(f(symbol)) },
                    left: Either.left
                )
        }
    }
}
