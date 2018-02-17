import Foundation

public extension ParserCoreProtocol {

    static func empty(tag: String? = nil) -> GenericParser<Self, ()> {
        return GenericParser(tag: tag, const(.right(Void())))
    }

    static func skip<Parser: ParserProtocol>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, ()> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            _ = core.parse(parser)
            return .right(Void())
        }
    }

    static func maybe<Parser: ParserProtocol>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, Parser.Symbol?> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            .right(core.parse(parser).right)
        }
    }

    static func many<Parser: ParserProtocol>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, [Parser.Symbol]> where
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

    static func some<Parser: ParserProtocol>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, [Parser.Symbol]> where
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

    static func list<Item: ParserProtocol, Separator: ParserProtocol>(tag: String? = nil, item: Item, separator: Separator) -> GenericParser<Self, [Item.Symbol]> where
        Item.Core == Self,
        Separator.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            core.parse(item)
                .map { first in
                    var items = [first]
                    while let _ = core.parse(separator).right,
                          let next = core.parse(item).right
                    {
                        items.append(next)
                    }
                    return .right(items)
                }
                .iif(right: id, left: const(.right([])))
        }
    }

    static func oneOf<Parser: ParserProtocol>(tag: String? = nil, _ parsers: Parser...) -> GenericParser<Self, Parser.Symbol> where
        Parser.Core == Self
    {
        return oneOf(tag: tag, parsers)
    }

    static func oneOf<Parser: ParserProtocol>(tag: String? = nil, _ parsers: [Parser]) -> GenericParser<Self, Parser.Symbol> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            for parser in parsers {
                let result = core.parse(parser)
                if case .right = result  {
                    return result
                }
            }
            let alternatives = parsers
                .map { $0.tag.unwrappedDescription }
                .joined(separator: " or ")
            return .left(Mismatch(tag: tag, .serializedExpectation(alternatives)))
        }
    }
}

public extension ParserCoreProtocol {

    static func end() -> GenericParser<Self, ()> {
        return GenericParser<Self, ()> { _, core in
            core.accept { tail -> Match<()>? in
                    return tail.count == 0 ? Match(symbol: (), length: 0) : nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: nil, .serializedExpectation("end of input")))
        }
    }

    static func string(
        tag: String? = nil,
        while predicate: @escaping (Source.SubSequence.Element) -> Bool
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence>? in
                    let match = tail.prefix(while: predicate)
                    return Match(symbol: match, length: match.count)
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag))
        }
    }
}

public extension ParserCoreProtocol where
    Source.SubSequence.Element: Equatable
{
    static func string(
        tag: String? = nil,
        _ pattern: Source.SubSequence
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence>? in
                    tail.starts(with: pattern) ? Match(symbol: pattern, length: pattern.count) : nil
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag, .expectation(pattern)))
        }
    }
}

public extension ParserCoreProtocol where
    Source == String
{
    static func string(tag: String? = nil, regex: RegEx) -> GenericParser<Self, (String, [String])> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<(String, [String])>? in
                    regex.firstMatch(in: String(tail), options: .anchored)
                        .map { Match(symbol: ($0.firstGroup, Array($0.groups.dropFirst())), length: $0.firstGroup.count) }
                }
                .map(Either.right)
            ??  .left(Mismatch(tag: tag, .serializedExpectation("text matching regular expression \(regex)")))
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
