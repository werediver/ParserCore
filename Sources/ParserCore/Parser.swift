public protocol ParserProtocol {

    associatedtype Core: ParserCoreProtocol
    associatedtype Symbol
    typealias Result = Either<Mismatch, Symbol>

    var tag: String? { get }

    func parse(_ core: Core) -> Result
}

public extension ParserProtocol {

    func map<T>(tag: String? = nil, _ transform: @escaping (Symbol) -> T) -> GenericParser<Core, T> {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .map(transform)
        }
    }

    func attemptMap<T>(tag: String? = nil, _ transform: @escaping (Symbol) -> Either<Mismatch, T>) -> GenericParser<Core, T> {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .flatMap(transform)
        }
    }

    func flatMap<P: ParserProtocol>(tag: String? = nil, _ transform: @escaping (Symbol) -> P) -> GenericParser<Core, P.Symbol> where
        P.Core == Core
    {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .iif(
                    right: { symbol in core.parse(transform(symbol)) },
                    left: Either.left
                )
        }
    }

    func mapError(tag: String? = nil, _ transform: @escaping (Mismatch) -> Mismatch) -> GenericParser<Core, Symbol> {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .mapLeft(transform)
        }
    }
}

public struct GenericParser<_Core: ParserCoreProtocol, _Symbol>: ParserProtocol {

    public typealias Core = _Core
    public typealias Symbol = _Symbol

    public let tag: String?

    public func parse(_ core: Core) -> Result {
        return body(self, core)
    }

    public init(tag: String? = nil, _ body: @escaping (_ this: GenericParser, Core) -> Result) {
        self.tag = tag
        self.body = body
    }

    private let body: (_ this: GenericParser, Core) -> Result
}

public extension GenericParser {

    init<Parser: ParserProtocol>(tag: String? = nil, _ body: @escaping (_ this: GenericParser, Core) -> Parser) where
        Parser.Core == Core,
        Parser.Symbol == Symbol
    {
        self.init(tag: tag) { this, core in core.parse(body(this, core)) }
    }
}
