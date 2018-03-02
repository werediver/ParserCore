/*

[+] Flexible `accept(_:)`
[ ] `parse(_:)`
    [+] Backtracking
    [+] Farthest failure tracking
        [ ] Deduplicate output
    [ ] Depth limiting
    [ ] Caching

*/

protocol SomeCore {

    associatedtype Source: Collection
    typealias Match<Symbol> = GenericMatch<Symbol, Source.Index>

    func accept<Symbol>(_ body: (Source.SubSequence) -> Match<Symbol>?) -> Symbol?
    func parse<Parser: SomeParser>(_ parser: Parser) -> Parser.Match where Parser.Core == Self
}

final class Core<_Source: Collection>: SomeCore {

    typealias Source = _Source

    private let source: Source
    private var position: Source.Index

    private lazy var tracer = Tracer(offset: { [source] position in source.distance(from: source.startIndex, to: position) })

    init(source: Source) {
        self.source = source
        self.position = source.startIndex
    }

    func accept<Symbol>(_ body: (Source.SubSequence) -> Match<Symbol>?) -> Symbol? {
        let tail = source.suffix(from: position)

        if let match = body(tail) {
            position = match.range.upperBound
            return match.symbol
        }

        return nil
    }

    func parse<Parser: SomeParser>(_ parser: Parser) -> Parser.Match where Parser.Core == Core {
        let startPosition = position

        let match = tracer.trace(position: position, tag: parser.tag) {
            parser.parse(core: self)
        }

        if case .left = match {
            position = startPosition
        }

        return match
    }
}
