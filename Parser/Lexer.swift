import Foundation

enum LexerError<TargetSymbol: TerminalSymbolType>: ErrorType {

    case UnknownToken(TargetSymbol.Source.Index)

}

class Lexer<TargetSymbol: TerminalSymbolType>: SequenceType {

    typealias Token = GenericToken<TargetSymbol, TargetSymbol.Source.Index>
    typealias Element = Result<Token, LexerError<TargetSymbol>>
    typealias Generator = AnyGenerator<Element>

    let src: TargetSymbol.Source

    init(src: TargetSymbol.Source) {
        self.src = src
    }

    func generate() -> Generator {
        let src = self.src
        var offset = src.startIndex
        var failed = false
        return AnyGenerator {
            var token: Token?
            let rest = src.suffixFrom(offset)
            if rest.count > 0 && !failed {
                for sym in TargetSymbol.all {
                    let len = sym.match(rest)
                    if len > 0 {
                        let tokenEnd = offset.advancedBy(len)
                        token = Token(sym: sym, start: offset, end: tokenEnd)
                        offset = tokenEnd
                        break
                    }
                }
                failed = (token == nil)
                return token.flatMap{ .Value($0) } ?? .Error(.UnknownToken(offset))
            } else {
                // It's possible to continue lexical analysis bypassing errors, but is it useful?
                // TODO: Implement ability to optionally bypass errors in Lexer.
                return nil // Stop iteration.
            }
        }
    }

}
