import RegEx

public extension SomeCore where
    Source == String
{
    static func string(tag: String? = nil, regex: RegEx) -> GenericParser<Self, (String, [String])> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<(String, [String])>? in
                    regex.firstMatch(in: String(tail), options: .anchored)
                        .map { Match(symbol: ($0.firstGroup, Array($0.groups.dropFirst())), range: tail.startIndex ..< tail.index(tail.startIndex, offsetBy: $0.firstGroup.count)) }
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag, reason: .expected("text matching regular expression \(regex)")))
        }
    }
}
