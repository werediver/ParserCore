public protocol ParserCoreProtocol {

    associatedtype Source: Collection where Source.SubSequence: Collection

    func accept<Symbol>(_ body: (Source.SubSequence) -> TerminalMatch<Symbol>?) -> Symbol?

    func parse<P: ParserProtocol>(_ parser: P) -> P.Link where P.Core == Self
}

public final class GenericParserCore<_Source: Collection>: ParserCoreProtocol where
    _Source.SubSequence: Collection,
    _Source.IndexDistance == Int // TODO: Consider dropping this constraint.
{
    public typealias Source = _Source

    private let source: Source
    private var position: Source.Index

    private func offset(_ index: Source.Index) -> Source.IndexDistance {
        return source.distance(from: source.startIndex, to: index)
    }

    public init(source: Source) {
        self.source = source
        self.position = source.startIndex
    }

    public func accept<Symbol>(_ body: (Source.SubSequence) -> TerminalMatch<Symbol>?) -> Symbol? {
        let tail = source.suffix(from: position)
        if let match = body(tail) {
            source.formIndex(&position, offsetBy: match.length)
            return match.symbol
        }
        return nil
    }

    public func parse<P: ParserProtocol>(_ parser: P) -> P.Link where
        P.Core == GenericParserCore
    {
        let startPosition = position
        let key = parser.tag.map { Key(offset: offset(position), tag: $0) }
        let result = wrap(key: key) { () -> Result<TerminalMatch<P.Symbol>, Mismatch> in
            stack.append((startPosition, parser.tag))
            defer { stack.removeLast() }
            //if let _ = parser.tag { print(trace) }
            return parser.parse(self).result
                .map { symbol in
                    TerminalMatch(symbol: symbol, length: source.distance(from: startPosition, to: position))
                }
        }

        //if case let .failure(error) = result {
        if case .failure = result {
            position = startPosition
            //print("\(offset(position)): \(error)")
        }
        return (result.map { match in match.symbol }, self)
    }

    // TODO: Consider "compressing" the stack in case of left recursion (add `depth: Int` field).
    private var stack: [(startPosition: Source.Index, tag: String?)] = []
    private var trace: String {
        return stack
            .filter { $0.tag != nil }
            .map { "\(offset($0.startPosition)):\($0.tag.unwrappedDescription)" }
            .joined(separator: " ")
    }

    private func wrap<Key: Hashable, Symbol>(key: Key?, _ f: () -> Result<TerminalMatch<Symbol>, Mismatch>) -> Result<TerminalMatch<Symbol>, Mismatch> {
        return depthLimiter.limitDepth(key: key, limit: source.count - offset(position), {
                    memoizer.memoize(key: key, context: self, {
                            AnyTerminalMatchResult(f())
                        })
                        .cast()
                    ??  .failure(Mismatch(message: trace + " Type cast error"))
                })
            ??  .failure(Mismatch(message: trace + " Depth cut-off"))
    }

    private var memoizer = Memoizer<GenericParserCore, AnyTerminalMatchResult>(
        shouldUpdate: { cached, candidate -> Bool in
            if let candidateMatch = candidate.value {
                if let cachedMatch = cached.value {
                    return candidateMatch.length > cachedMatch.length
                }
                return true
            }
            return false
        },
        willReturnFromCache: { context, cached in
            if  let match = cached.value,
                let startPosition = context.stack.last?.startPosition
            {
                context.position = context.source.index(startPosition, offsetBy: match.length)
            }
        }
    )

    private let depthLimiter = DepthLimiter()
}
