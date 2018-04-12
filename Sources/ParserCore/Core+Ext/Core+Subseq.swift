public extension SomeCore {

    static func subseq(
        tag: String? = nil,
        while predicate: @escaping (Source.SubSequence.Element) -> Bool,
        count limit: CountLimit = .atLeast(1)
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence>? in
                    var count = 0
                    let match = tail.prefix(while: { element in
                        if limit.extends(past: count) && predicate(element) {
                            count += 1
                            return true
                        }
                        return false
                    })

                    if limit.contains(match.count) {
                        return Match(symbol: match, range: match.startIndex ..< match.endIndex)
                    }
                    return nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag))
        }
    }
}

public extension SomeCore where
    Source.SubSequence.Element: Equatable
{
    static func subseq(
        tag: String? = nil,
        _ pattern: Source.SubSequence
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence>? in
                    if tail.starts(with: pattern) {
                        return Match(symbol: pattern, range: tail.startIndex ..< tail.index(tail.startIndex, offsetBy: pattern.count))
                    }
                    return nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag, reason: .expected(String(reflecting: pattern))))
        }
    }
}
