import Foundation

protocol TerminalSymbol: Equatable {

    func match(src: String) -> Int

}

extension TerminalSymbol where Self: RawRepresentable, Self.RawValue == RegEx {

    func match(src: String) -> Int {
        return rawValue.rangeOfFirstMatchInString(src)?.count ?? 0
    }

}

struct Lexer<Sym: TerminalSymbol>: SequenceType {

    typealias Generator = LexerGen<Sym>

    let syms: [Sym]
    let src: String

    init(syms: [Sym], src: String) {
        self.syms = syms
        self.src = src
    }

    func generate() -> Generator {
        return Generator(syms: syms, src: src)
    }

}

struct LexerGen<Symbol: TerminalSymbol>: GeneratorType {

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
