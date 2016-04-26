import Foundation

struct UnknownTokenError<TargetSymbol: TerminalSymbolType>: ErrorType {

    let range: Range<TargetSymbol.Source.Index>

}

final class Lexer<TargetSymbol: TerminalSymbolType>: SequenceType {

    typealias Token = GenericToken<TargetSymbol, TargetSymbol.Source.Index>
    typealias Element = Result<Token, UnknownTokenError<TargetSymbol>>
    typealias Generator = AnyGenerator<Element>

    let src: TargetSymbol.Source

    init(src: TargetSymbol.Source) {
        self.src = src
    }

    private func findToken(offset: TargetSymbol.Source.Index) -> Token? {
        var token: Token?
        let rest = src.suffixFrom(offset)
        if  rest.count > 0 {
            for sym in TargetSymbol.all {
                let len = sym.match(rest)
                if len > 0 {
                    token = Token(sym: sym, range: offset ..< offset.advancedBy(len))
                    break
                }
            }
        }
        return token
    }

    func analyse(offset: TargetSymbol.Source.Index) -> Element? {
        if src.fullRange.contains(offset) {
            if let token = findToken(offset) {
                return .Value(token)
            } else {
                let unknownTokenStart = offset
                var unknownTokenEnd = offset.advancedBy(1)
                while src.fullRange.contains(unknownTokenEnd)
                   && findToken(unknownTokenEnd) == nil
                {
                    unknownTokenEnd = unknownTokenEnd.advancedBy(1)
                }
                return .Error(UnknownTokenError(range: unknownTokenStart ..< unknownTokenEnd))
            }
        } else {
            return nil
        }
    }

    func generate() -> Generator {
        let src = self.src
        var offset = src.startIndex
        return AnyGenerator {
            let result = self.analyse(offset)

            if let result = result,
               let nextOffset = result.value?.range.endIndex ?? result.error?.range.endIndex
            {
                offset = nextOffset
            }

            return result
        }
    }

}
