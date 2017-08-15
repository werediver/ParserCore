import Foundation

public extension ParserCoreProtocol {

    static func skip<Parser: ParserProtocol>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, ()> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            let link1 = core.parse(parser)
            return (.success(), link1.core)
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
        // TODO: Reuse each returned core, don't discard them!
        return GenericParser(tag: tag) { _, core in
            for parser in parsers {
                let link = core.parse(parser)
                if case .success = link.result  {
                    return link
                }
            }
            return (.failure(Mismatch(message: "One of \(tag.unwrappedDescription) is expected")), core)
        }
    }
}

public extension ParserCoreProtocol {

    static func end() -> GenericParser<Self, ()> {
        return GenericParser<Self, ()> { _, core in
            core.accept { tail -> TerminalMatch<()>? in
                    return tail.count == 0 ? TerminalMatch(symbol: (), length: 0) : nil
                }
                .map { symbol in (.success(symbol), core) }
            ??  (.failure(Mismatch(message: "End of input is expected")), core)
        }
    }

    static func string(
        tag: String? = nil,
        while predicate: @escaping (Source.SubSequence.Iterator.Element) -> Bool
    ) -> GenericParser<Self, Source.SubSequence> {
        return GenericParser(tag: tag) { _, core in
            core.accept { tail -> TerminalMatch<Source.SubSequence>? in
                    let match = tail.prefix(while: predicate)
                    if match.count > 0 {
                        return TerminalMatch(symbol: match, length: match.count)
                    } else {
                        return nil
                    }
                }
                .map { symbol in (.success(symbol), core) }
            ??  (.failure(Mismatch()), core)
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
            core.accept { tail -> TerminalMatch<Source.SubSequence>? in
                    tail.starts(with: pattern) ? TerminalMatch(symbol: pattern, length: pattern.count) : nil
                }
                .map { symbol in (.success(symbol), core) }
            ??  (.failure(Mismatch()), core)
        }
    }
}

public extension ParserCoreProtocol where
    Source == String.CharacterView
{
    static func string(tag: String? = nil, _ pattern: String) -> GenericParser<Self, String> {
        return string(tag: tag, pattern.characters).map(String.init)
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
