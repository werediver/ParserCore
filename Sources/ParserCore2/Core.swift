/*

[+] Flexible `accept(_:)`
[+] `parse(_:)`
    [+] Backtracking
    [+] Farthest failure tracking
        [ ] Deduplicate output
    [+] Left recursion accomodation
        [+] Depth limiting
            [ ] Tail length overestimating heuristic
        [+] Caching

*/

public protocol SomeCore {

    associatedtype Source: Collection
    typealias Match<Symbol> = GenericMatch<Symbol, Source.Index>

    func accept<Symbol>(_ body: (Source.SubSequence) -> Match<Symbol>?) -> Symbol?
    func parse<Parser: SomeParser>(_ parser: Parser) -> Parser.Match where Parser.Core == Self
}

public final class Core<_Source: Collection>: SomeCore where
    _Source.IndexDistance == Int
{
    public typealias Source = _Source

    private let source: Source
    private var position: Source.Index

    public private(set) lazy var tracer = DepthLimiter(
            sourceLength: source.count,
            tailLength: { [source] position in source.distance(from: position, to: source.endIndex) }
        )
        .combine(
            with: Memoizer(delegate: self)
        )
        .combine(
            with: FarthestMismatchTracer(
                offset: { [source] position in source.distance(from: source.startIndex, to: position) }
            )
        )

    public init(source: Source) {
        self.source = source
        self.position = source.startIndex
    }

    public func accept<Symbol>(_ body: (Source.SubSequence) -> Match<Symbol>?) -> Symbol? {
        let tail = source.suffix(from: position)

        if let match = body(tail) {
            position = match.range.upperBound
            return match.symbol
        }

        return nil
    }

    public func parse<Parser: SomeParser>(_ parser: Parser) -> Parser.Match where Parser.Core == Core {
        let startPosition = position

        let match = tracer.trace(position: position, tag: parser.tag) {
            parser.parse(core: self)
                .map { symbol in Match(symbol: symbol, range: startPosition ..< position) }
        }

        if case .left = match {
            position = startPosition
        }

        return match
            .map { match in match.symbol }
    }
}

extension Core: MemoizerDelegate {

    public typealias Index = Source.Index

    public func memoizer(shouldUpdate cached: Value, with candidate: Value) -> Bool {
        if case let .right(candidateMatch) = candidate {
            if case let .right(cachedMatch) = cached {
                return candidateMatch.range.upperBound > cachedMatch.range.upperBound
            }
            return true
        }
        return false
    }

    public func memoizer(willReturnCached value: Value) {
        if case let .right(match) = value {
            position = match.range.upperBound
        }
    }
}
