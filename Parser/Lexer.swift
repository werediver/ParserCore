import Foundation

class Lexer<TerminalSymbol: TerminalSymbolType>: SequenceType {

    typealias Token = GenericToken<TerminalSymbol, TerminalSymbol.Source.Index>
    typealias Generator = AnyGenerator<Token>

    let src: TerminalSymbol.Source

    init(src: TerminalSymbol.Source) {
        self.src = src
    }

    func generate() -> Generator {
        let src = self.src
        var offset = src.startIndex
        return AnyGenerator {
            var token: Token?
            let rest = src.suffixFrom(offset)
            if rest.count > 0 {
                for sym in TerminalSymbol.all {
                    let len = sym.match(rest)
                    if len > 0 {
                        let tokenEnd = offset.advancedBy(len)
                        token = Token(sym: sym, start: offset, end: tokenEnd)
                        offset = tokenEnd
                    }
                }
                if token == nil {
                    //throw xxx // Can't throw here.
                    print("Lexer FAILED")
                }
            }
            return token
        }
    }

}

// MARK: - `String` support

struct CaretPosition: CustomStringConvertible {

    var line: Int
    var column: Int

    var description: String { return "\(line):\(column)" }

}

extension Lexer
    where TerminalSymbol.Source == String.CharacterView
{

    convenience init(src: String) {
        self.init(src: src.characters)
    }

    func caretPosition(srcIndex: TerminalSymbol.Source.Index) -> CaretPosition {
        let eols = (src.startIndex ..< srcIndex).flatMap { (src[$0] == "\n") ? $0 : nil }
        let (line, lineStartIndex) = eols.fullRange.flatMap({ (eols[$0] < srcIndex) ? ($0, eols[$0]) : nil }).last ?? (0, src.startIndex)
        let column = lineStartIndex.distanceTo(srcIndex)
        return CaretPosition(line: line, column: column)
    }

    func tokenDescription(token: Token) -> String {
        let pos = caretPosition(token.start)
        return "<\(token.sym) \(pos) \"\(String(src[token.range]))\">"
    }

}

extension TerminalSymbolType
    where Source == String.CharacterView,
          Self: RawRepresentable, Self.RawValue == RegEx
{

    func match(src: Source.SubSequence) -> Source.Index.Distance {
        return rawValue.rangeOfFirstMatchInString(String(src), options: .Anchored)?.count ?? 0
    }

}
