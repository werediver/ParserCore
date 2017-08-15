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

    typealias Link = (result: Result<Symbol, Mismatch>, core: Core)

    var tag: String? { get }

    func parse(_ core: Core) -> Link
}

public extension ParserProtocol {

    func map<T>(tag: String? = nil, _ transform: @escaping (Symbol) -> T) -> GenericParser<Core, T> {
        return GenericParser(tag: tag) { _, core in
            let link1 = core.parse(self)
            let link2 = (link1.result.map(transform), link1.core)
            return link2
        }
    }

    func attemptMap<T>(tag: String? = nil, _ transform: @escaping (Symbol) -> Result<T, Mismatch>) -> GenericParser<Core, T> {
        return GenericParser(tag: tag) { _, core in
            let link1 = core.parse(self)
            let link2 = (link1.result.flatMap(transform), link1.core)
            return link2
        }
    }

    func flatMap<P: ParserProtocol>(tag: String? = nil, _ transform: @escaping (Symbol) -> P) -> GenericParser<Core, P.Symbol> where
        P.Core == Core
    {
        return GenericParser(tag: tag) { _, core in
            let link1 = core.parse(self)
            let link2 = link1.result.iif(
                success: { symbol in link1.core.parse(transform(symbol)) },
                failure: { error in (.failure(error), link1.core) }
            )
            return link2
        }
    }

    func mapError(tag: String? = nil, _ transform: @escaping (Mismatch) -> Mismatch) -> GenericParser<Core, Symbol> {
        return GenericParser(tag: tag) { _, core in
            let link1 = core.parse(self)
            let link2 = (link1.result.mapError(transform), link1.core)
            return link2
        }
    }
}

public struct GenericParser<_Core: ParserCoreProtocol, _Symbol>: ParserProtocol {

    public typealias Core = _Core
    public typealias Symbol = _Symbol

    public let tag: String?

    public func parse(_ core: Core) -> Link {
        return body(self, core)
    }

    public init(tag: String? = nil, _ body: @escaping (_ this: GenericParser, Core) -> Link) {
        self.tag = tag
        self.body = body
    }

    private let body: (_ this: GenericParser, Core) -> Link
}

public extension GenericParser {

    init<Parser: ParserProtocol>(tag: String? = nil, _ body: @escaping (_ this: GenericParser, Core) -> Parser) where
        Parser.Core == Core,
        Parser.Symbol == Symbol
    {
        self.init(tag: tag) { this, core in core.parse(body(this, core)) }
    }
}
