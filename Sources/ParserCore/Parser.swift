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

    typealias Output = Result<(symbol: Symbol, core: Core), Mismatch>

    var tag: String? { get }

    func parse(_ core: Core) -> Output
}

public extension ParserProtocol {

    func map<U>(tag: String? = nil, _ transform: @escaping (Symbol) -> U) -> GenericParser<Core, U> {
        return GenericParser(tag: tag) { _, core -> GenericParser<Core, U>.Output in
            core.parse(self)
                .map { match -> GenericParser<Core, U>.Output.Value in
                    (transform(match.symbol), match.core)
                }
        }
    }

    func flatMap<U>(tag: String? = nil, _ transform: @escaping (Symbol) -> Result<U, Mismatch>) -> GenericParser<Core, U> {
        return GenericParser(tag: tag) { _, core -> GenericParser<Core, U>.Output in
            core.parse(self)
                .flatMap { match -> GenericParser<Core, U>.Output in
                    transform(match.symbol).map { ($0, match.core) }
                }
        }
    }

    func flatMap<Parser: ParserProtocol>(tag: String? = nil, _ transform: @escaping (Symbol) -> Parser) -> GenericParser<Core, Parser.Symbol> where
        Parser.Core == Core
    {
        return GenericParser(tag: tag) { _, core -> GenericParser<Core, Parser.Symbol>.Output in
            core.parse(self)
                .flatMap { match -> GenericParser<Core, Parser.Symbol>.Output in
                    match.core.parse(transform(match.symbol))
                }
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
