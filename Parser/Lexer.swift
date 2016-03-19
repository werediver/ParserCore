import Foundation

class Lexer<TS: TerminalSymbol>: SequenceType {

    typealias Token = GenericToken<TS, TS.Source.Index>
    typealias Generator = AnyGenerator<Token>

    let src: TS.Source

    init(src: TS.Source) {
        self.src = src
    }

    func generate() -> Generator {
        let src = self.src
        var offset = src.startIndex
        return anyGenerator {
            var token: Token?
            let rest = src.suffixFrom(offset)
            if rest.count > 0 {
                for sym in TS.all {
                    let len = sym.match(rest)
                    if len > 0 {
                        let tokenEnd = offset.advancedBy(len)
                        token = Token(sym: sym, start: offset, end: tokenEnd)
                        offset = tokenEnd
                    }
                }
                if token == nil {
                    //throw xxx
                }
            }
            return token
        }
    }

}

// MARK: - `String` support

extension Lexer
    where TS.Source == String.CharacterView
{

    convenience init(src: String) {
        self.init(src: src.characters)
    }

}

extension TerminalSymbol
    where Source == String.CharacterView,
          Self: RawRepresentable, Self.RawValue == RegEx
{

    func match(src: Source.SubSequence) -> Source.Index.Distance {
        return rawValue.rangeOfFirstMatchInString(String(src), options: .Anchored)?.count ?? 0
    }

}
