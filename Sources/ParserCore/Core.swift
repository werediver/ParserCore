public protocol SomeCore: class {

    associatedtype Source: Collection where Source.SubSequence: Collection

    func accept<Symbol>(_ body: (Source.SubSequence) -> Match<Symbol>?) -> Symbol?

    func parse<P: SomeParser>(_ parser: P) -> P.Result where P.Core == Self
}

public final class GenericCore<_Source: Collection>: SomeCore where
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

    public func accept<Symbol>(_ body: (Source.SubSequence) -> Match<Symbol>?) -> Symbol? {
        let tail = source.suffix(from: position)
        if let match = body(tail) {
            source.formIndex(&position, offsetBy: match.length)
            return match.symbol
        }
        return nil
    }

    public func parse<P: SomeParser>(_ parser: P) -> P.Result where
        P.Core == GenericCore
    {
        let startPosition = position
        let key = parser.tag.map { Key(offset: offset(position), tag: $0) }
        let result = wrap(key: key) { () -> Either<Mismatch, Match<P.Symbol>> in
            stack.append((startPosition, parser.tag))
            defer { stack.removeLast() }
            //if let _ = parser.tag { print(trace) }
            return parser.parse(self)
                .map { symbol in
                    Match(symbol: symbol, length: source.distance(from: startPosition, to: position))
                }
        }

        if case let .left(mismatch) = result {
        //if case .left = result {
            if farthestFailure?.position ?? source.startIndex < position {
                farthestFailure = (position, [(trace, mismatch)])
            } else if farthestFailure?.position ?? source.startIndex == position {
                farthestFailure = (position, (farthestFailure?.failures ?? []) + [(trace, mismatch)])
            }

            position = startPosition
            //print("\(offset(position)): \(error)")
        } else if case .right = result {
            if farthestFailure?.position ?? source.startIndex < position {
                farthestFailure = nil
            }
        }

        return result.map { match in match.symbol }
    }

    // TODO: Consider "compressing" the stack in case of left recursion (add `depth: Int` field).
    private var stack: [(startPosition: Source.Index, tag: String?)] = []
    private var trace: String {
        return stack
            .reversed()
            .filter { $0.tag != nil }
            .map { "\(offset($0.startPosition)):\($0.tag.someDescription)" }
            .joined(separator: " ◂ ")
    }

    public var farthestFailure: (position: Source.Index, failures: [(trace: String, mismatch: Mismatch)])?

    private func wrap<Key: Hashable, Symbol>(key: Key?, _ f: () -> Either<Mismatch, Match<Symbol>>) -> Either<Mismatch, Match<Symbol>> {
        return depthLimiter.limitDepth(key: key, limit: source.distance(from: position, to: source.endIndex), {
                    memoizer.memoize(key: key, context: self, {
                            AnyMatchResult(f())
                        })
                        .cast()
                    ??  .left(Mismatch(message: trace + " Type cast error"))
                })
            ??  .left(Mismatch(message: trace + " Depth cut-off"))
    }

    private let memoizer = Memoizer<GenericCore, AnyMatchResult>(
        shouldUpdate: { cached, candidate -> Bool in
            if let candidateMatch = candidate.right {
                if let cachedMatch = cached.right {
                    return candidateMatch.length > cachedMatch.length
                }
                return true
            }
            return false
        },
        willReturnFromCache: { context, cached in
            if  let match = cached.right,
                let startPosition = context.stack.last?.startPosition
            {
                context.position = context.source.index(startPosition, offsetBy: match.length)
            }
        }
    )

    private let depthLimiter = DepthLimiter()
}
