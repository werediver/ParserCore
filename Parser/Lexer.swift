import Foundation

extension TerminalSymbol where Self.Source == String, Self: RawRepresentable, Self.RawValue == RegEx {

    func match(src: Source) -> Int {
        return rawValue.rangeOfFirstMatchInString(src)?.count ?? 0
    }

}

struct Lexer<Symbol: TerminalSymbol
    where Symbol.Source == String>: SequenceType {

    typealias Generator = LexerGen<Symbol>

    let syms: [Symbol]
    let src: String

    init(syms: [Symbol], src: String) {
        self.syms = syms
        self.src = src
    }

    func generate() -> Generator {
        return Generator(syms: syms, src: src)
    }

}

struct LexerGen<Symbol: TerminalSymbol
    where Symbol.Source == String>: GeneratorType {

    typealias Element = TextToken<Symbol>

    let syms: [Symbol]
    let src: String
    var offset = 0

    init(syms: [Symbol], src: String) {
        self.syms = syms
        self.src = src
    }

    mutating func next() -> Element? {
        var token: Element? = nil

        let start = src.startIndex.advancedBy(offset)
        let rest  = src.substringFromIndex(start)

        for sym in syms {
            let len = sym.match(rest)
            if  len > 0 {
                let end = start.advancedBy(len)
                token = Element(sym: sym, start: start, end: end)
                offset += len
                break
            }
        }

        return token
    }

}
