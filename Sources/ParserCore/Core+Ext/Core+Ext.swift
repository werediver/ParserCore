public extension SomeCore {

    static func empty(tag: String? = nil) -> GenericParser<Self, ()> {
        return GenericParser(tag: tag, const(.right(Void())))
    }

    static func end() -> GenericParser<Self, ()> {
        return GenericParser<Self, ()> { _, core in
            core.accept { tail -> Match<()>? in
                    if tail.startIndex == tail.endIndex {
                        return Match(symbol: (), range: tail.startIndex ..< tail.endIndex)
                    }
                    return nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: nil, expectation: .text("end of input")))
        }
    }

    static func maybe<Parser: SomeParser>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, Parser.Symbol?> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            .right(core.parse(parser).right)
        }
    }

    static func many<Parser: SomeParser>(
        tag: String? = nil,
        _ parser: Parser,
        count limit: CountLimit
    ) -> GenericParser<Self, [Parser.Symbol]> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            var items = [Parser.Symbol]()
            while limit.extends(past: items.count),
                  let next = core.parse(parser).right {
                items.append(next)
            }

            if limit.contains(items.count) {
                return .right(items)
            }
            return .left(Mismatch(tag: tag, expectation: parser.tag.map { tag in .text("\(limit) \(tag)") }))
        }
    }

    // TODO: Optionally allow trailing comma.
    static func list<Item: SomeParser, Separator: SomeParser>(tag: String? = nil, item: Item, separator: Separator) -> GenericParser<Self, [Item.Symbol]> where
        Item.Core == Self,
        Separator.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            core.parse(item)
                .map { first in
                    var items = [first]
                    let followingItem = separator.flatMap(const(item))
                    while let next = core.parse(followingItem).right {
                        items.append(next)
                    }
                    return .right(items)
                }
                .iif(right: id, left: const(.right([])))
        }
    }

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

            var expectation: Mismatch.Expectation?
            if parsers.compactMap({ $0.tag }).count > 0 {
                let alternatives = parsers
                    .map { describe($0.tag) }
                    .joined(separator: " or ")
                expectation = .text(alternatives)
            }
            return .left(Mismatch(tag: tag, expectation: expectation))
        }
    }

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
                    expectation: Mismatch.Expectation.text(
                        alternatives
                            .map(String.init(describing:))
                            .joined(separator: " or ")
                    )
                ))
        }
    }

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
            ??  .left(Mismatch(tag: tag, expectation: .object(pattern)))
        }
    }
}
