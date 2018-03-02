protocol SomeParser {

    associatedtype Core: SomeCore
    associatedtype Symbol

    typealias Match = Either<Mismatch, Symbol>

    var tag: String? { get }

    func parse(core: Core) -> Match
}

struct GenericParser<_Core: SomeCore, _Symbol>: SomeParser {

    typealias Core = _Core
    typealias Symbol = _Symbol

    typealias Body = (GenericParser, Core) -> Match

    private let body: Body

    let tag: String?

    init(tag: String? = nil, _ body: @escaping Body) {
        self.tag = tag
        self.body = body
    }

    func parse(core: Core) -> Match {
        return body(self, core)
    }
}
