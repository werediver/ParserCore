import Foundation

public extension ParserCoreProtocol {

    static func skip<Parser: ParserProtocol>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, ()> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            _ = core.parse(parser)
            return .right(Void())
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
        while predicate: @escaping (Source.SubSequence.Iterator.Element) -> Bool
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
