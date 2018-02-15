import Foundation

public extension ParserCoreProtocol {

    static func empty(tag: String? = nil) -> GenericParser<Self, ()> {
        return GenericParser(tag: tag) { _, _ in
            .right(Void())
        }
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
            core.parse(parser)
                .iif(right: Either.right, left: const(.right(nil)))
        }
        /* return oneOf(
                tag: tag,
                parser.map(Optional.init),
                empty().map(const(nil))
            ) */
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
            return .left(Mismatch(message: "One of \(tag.unwrappedDescription) is expected"))
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
            ??  .left(Mismatch(message: "End of input is expected"))
        }
    }

    static func string(
        tag: String? = nil,
        while predicate: @escaping (Source.SubSequence.Element) -> Bool
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> Match<Source.SubSequence>? in
                    let match = tail.prefix(while: predicate)
                    if match.count > 0 {
                        return Match(symbol: match, length: match.count)
                    } else {
                        return nil
                    }
                }
                .map(Either.right)
            ??  .left(Mismatch())
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
            ??  .left(Mismatch())
        }
    }
}

public extension ParserCoreProtocol where
    Source == String
{
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
