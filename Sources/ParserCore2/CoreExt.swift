import Foundation

public extension SomeCore {

    static func empty(tag: String? = nil) -> GenericParser<Self, ()> {
        return GenericParser(tag: tag, const(.right(Void())))
    }

    static func maybe<Parser: SomeParser>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, Parser.Symbol?> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            .right(core.parse(parser).right)
        }
    }

    static func many<Parser: SomeParser>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, [Parser.Symbol]> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            var items = [Parser.Symbol]()
            while let next = core.parse(parser).right {
                items.append(next)
            }
            return .right(items)
        }
    }

    static func some<Parser: SomeParser>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, [Parser.Symbol]> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            core.parse(parser)
                .map { first in
                    var items = [first]
                    while let next = core.parse(parser).right {
                        items.append(next)
                    }
                    return items
                }
        }
    }

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
            if parsers.flatMap({ $0.tag }).count > 0 {
                let alternatives = parsers
                    .map { describe($0.tag) }
                    .joined(separator: " or ")
                expectation = .text(alternatives)
            }
            return .left(Mismatch(tag: tag, expectation: expectation))
        }
    }
}

public extension SomeCore {

    static func end() -> GenericParser<Self, ()> {
        return GenericParser<Self, ()> { _, core in
            core.accept { tail -> Match<()>? in
                    tail.startIndex == tail.endIndex ? Match(symbol: (), range: tail.startIndex ..< tail.endIndex) : nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: nil, expectation: .text("end of input")))
        }
    }
}

extension SomeCore where
    Source.SubSequence: Collection
{
    static func string(
        tag: String? = nil,
        while predicate: @escaping (Source.SubSequence.Element) -> Bool
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence>? in
                    let match = tail.prefix(while: predicate)
                    return match.count > 0 ? Match(symbol: match, range: match.startIndex ..< match.endIndex) : nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag))
        }
    }
}

public extension SomeCore where
    Source.SubSequence: Collection,
    Source.SubSequence.IndexDistance == Source.IndexDistance,
    Source.SubSequence.Element: Equatable
{
    static func string(
        tag: String? = nil,
        _ pattern: Source.SubSequence
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence>? in
                    tail.starts(with: pattern) ? Match(symbol: pattern, range: tail.startIndex ..< tail.index(tail.startIndex, offsetBy: pattern.count)) : nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag, expectation: .object(pattern)))
        }
    }
}

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
            ??  .left(Mismatch(tag: tag, expectation: .text("text matching regular expression \(regex)")))
        }
    }

    static func string(tag: String? = nil, charset: CharacterSet) -> GenericParser<Self, String> {
        return string(tag: tag, while: charset.contains).map(String.init)
    }
}

private extension CharacterSet {

    func contains(_ c: Character) -> Bool {
        for scalar in String(c).unicodeScalars {
            if !self.contains(scalar) {
                return false
            }
        }
        return true
    }
}
