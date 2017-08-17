public struct Mismatch {

    public let message: String?

    public init(message: String? = nil) {
        self.message = message
    }
}

extension Mismatch: CustomStringConvertible {
    public var description: String { return message ?? "No match" }
}

public protocol ParserProtocol {

    associatedtype Core: ParserCoreProtocol
    associatedtype Symbol
    typealias Output = Result<Symbol, Mismatch>

    var tag: String? { get }

    func parse(_ core: Core) -> Output
}

public extension ParserProtocol {

    func map<T>(tag: String? = nil, _ transform: @escaping (Symbol) -> T) -> GenericParser<Core, T> {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .map(transform)
        }
    }

    func attemptMap<T>(tag: String? = nil, _ transform: @escaping (Symbol) -> Result<T, Mismatch>) -> GenericParser<Core, T> {
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
                    success: { symbol in core.parse(transform(symbol)) },
                    failure: Result.failure
                )
        }
    }

    func mapError(tag: String? = nil, _ transform: @escaping (Mismatch) -> Mismatch) -> GenericParser<Core, Symbol> {
        return GenericParser(tag: tag) { _, core in
            core.parse(self)
                .mapError(transform)
        }
    }
}

public struct GenericParser<_Core: ParserCoreProtocol, _Symbol>: ParserProtocol {

    public typealias Core = _Core
    public typealias Symbol = _Symbol

    public let tag: String?

    public func parse(_ core: Core) -> Output {
        return body(self, core)
    }

    public init(tag: String? = nil, _ body: @escaping (_ this: GenericParser, Core) -> Output) {
        self.tag = tag
        self.body = body
    }

    private let body: (_ this: GenericParser, Core) -> Output
}

public extension GenericParser {

    init<Parser: ParserProtocol>(tag: String? = nil, _ body: @escaping (_ this: GenericParser, Core) -> Parser) where
        Parser.Core == Core,
        Parser.Symbol == Symbol
    {
        self.init(tag: tag) { this, core in core.parse(body(this, core)) }
    }
}
