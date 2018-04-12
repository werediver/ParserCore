public protocol SomeCore {

    associatedtype Source: Collection
    typealias Match<Symbol> = GenericMatch<Symbol, Source.Index>

    func accept<Symbol>(_ body: (Source.SubSequence) -> Match<Symbol>?) -> Symbol?
    func parse<Parser: SomeParser>(_ parser: Parser) -> Parser.Match where Parser.Core == Self
}

public final class Core<_Source: Collection>: SomeCore where
    _Source.Index: Hashable
{

    public typealias Source = _Source
    public typealias OverestimatedCount = (Source.SubSequence) -> Int

    private let source: Source
    private var position: Source.Index
    private let overestimatedCount: OverestimatedCount

    public private(set) lazy var tracer = EmptyTracer<Source.Index>()
        .combine(
            with: DepthLimiter(
                sourceLength: overestimatedCount(source.suffix(from: source.startIndex)),
                tailLength: { [source, overestimatedCount] position in
                    overestimatedCount(source.suffix(from: position))
                }
            )
        )
        .combine(
            with: Memoizer(delegate: self)
        )
        .combine(
            with: FarthestMismatchTracer(
                offset: { [source] position in source.distance(from: source.startIndex, to: position) }
            )
        )

    public init(source: Source, overestimatedCount: OverestimatedCount? = nil) {
        self.source = source
        self.position = source.startIndex
        self.overestimatedCount = overestimatedCount ?? { [source] subsequence in
            source.distance(from: subsequence.startIndex, to: subsequence.endIndex)
        }
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

public extension Core where
    Source == String
{

    convenience init(source: Source) {
        self.init(source: source, overestimatedCount: { substring in substring.utf16.count })
    }
}
