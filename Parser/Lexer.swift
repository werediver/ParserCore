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
