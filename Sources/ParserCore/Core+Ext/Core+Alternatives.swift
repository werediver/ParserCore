public extension SomeCore {

    static func oneOf<Parser: SomeParser>(tag: String? = nil, _ parsers: Parser...) -> GenericParser<Self, Parser.Symbol> where
        Parser.Core == Self
    {
        return oneOf(tag: tag, parsers)
    }

    static func oneOf<Parser: SomeParser>(tag: String? = nil, _ parsers: [Parser]) -> GenericParser<Self, Parser.Symbol> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            for parser in parsers {
                let result = core.parse(parser)
                if case .right = result  {
                    return result
                }
            }

            var reason: Mismatch.Reason?
            if parsers.compactMap({ $0.tag }).count > 0 {
                let alternatives = parsers
                    .map { describe($0.tag) }
                    .joined(separator: " or ")
                reason = .expected(alternatives)
            }
            return .left(Mismatch(tag: tag, reason: reason))
        }
    }
}

public extension SomeCore where
    Source.SubSequence.Element: Equatable
{
    static func oneOf(tag: String? = nil, _ alternatives: [Source.SubSequence.Element]) -> GenericParser<Self, Source.SubSequence.Element> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence.Element>? in
                    if let element = tail.first, alternatives.contains(element) {
                        return Match(symbol: element, range: tail.startIndex ..< tail.index(after: tail.startIndex))
                    }
                    return nil
                }
                .map(Either.right)
            ??  .left(Mismatch(
                    tag: tag,
                    reason: .expected(
                        alternatives
                            .map(String.init(reflecting:))
                            .joined(separator: " or ")
                    )
                ))
        }
    }
}
