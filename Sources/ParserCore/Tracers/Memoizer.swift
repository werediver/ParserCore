public protocol MemoizerDelegate: class {

    associatedtype Index: Comparable

    typealias Value = Either<Mismatch, GenericMatch<Any, Index>>

    func memoizer(shouldUpdate cached: Value, with candidate: Value) -> Bool
    func memoizer(willReturnCached value: Value)
}

public final class Memoizer<Index, Delegate: MemoizerDelegate>: Tracing where
    Delegate.Index == Index
{
    typealias Value = Either<Mismatch, GenericMatch<Any, Index>>

    private var cache = IndexDictionary<Key<Index>, Value>()
    private weak var delegate: Delegate?

    init(delegate: Delegate) {
        self.delegate = delegate
    }

    public func trace<Symbol>(position: Index, tag: String?, call body: () -> Either<Mismatch, GenericMatch<Symbol, Index>>) -> Either<Mismatch, GenericMatch<Symbol, Index>> {
        guard let tag = tag
        else { return body() }

        let key = Key(position: position, tag: tag)
        if let cached = cache[key] {
            willReturnCached(cached)
            return unpack(cached)
        } else {
            let candidate = body()
            let packedCandidate = pack(candidate)
            if let cached = cache[key],
                !shouldUpdate(cached: cached, with: packedCandidate)
            {
                willReturnCached(cached)
                return unpack(cached)
            }
            cache[key] = packedCandidate
            return candidate
        }
    }

    public func report() -> String? { return nil }

    private func pack<Symbol>(_ match: Either<Mismatch, GenericMatch<Symbol, Index>>) -> Either<Mismatch, GenericMatch<Any, Index>> {
        return match.iif(
            right: { match in .right(GenericMatch(symbol: match.symbol, range: match.range)) },
            left: Either.left
        )
    }

    private func unpack<Symbol>(_ match: Either<Mismatch, GenericMatch<Any, Index>>) -> Either<Mismatch, GenericMatch<Symbol, Index>> {
        return match.iif(
            right: { match in
                (match.symbol as? Symbol)
                    .map { symbol in
                        .right(GenericMatch(symbol: symbol, range: match.range))
                    }
                ??  .left(Mismatch(message: "Cache record type mismatch (duplicate tags?)"))
            },
            left: Either.left
        )
    }

    private func shouldUpdate(cached: Value, with candidate: Value) -> Bool {
        return delegate?.memoizer(shouldUpdate: cached, with: candidate) ?? false
    }

    private func willReturnCached(_ value: Value) {
        delegate?.memoizer(willReturnCached: value)
    }
}

struct Key<Index: Comparable> {
    let position: Index
    let tag: String
}

extension Key: Equatable {

    static func ==(lhs: Key, rhs: Key) -> Bool {
        return lhs.position == rhs.position
            && lhs.tag == rhs.tag
    }
}

extension Key: Comparable {

    static func <(lhs: Key, rhs: Key) -> Bool {
        return lhs.position < rhs.position
            || lhs.position == rhs.position && lhs.tag < rhs.tag
    }
}
