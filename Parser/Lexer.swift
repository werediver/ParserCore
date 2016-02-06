import Foundation

protocol LexSym {

    func match(s: String) -> Int

}

struct LexToken<LexSym> {

    var sym: LexSym
    var range: Range<String.Index>

}

struct Lexer<Sym: LexSym>: SequenceType {

    typealias Generator = LexerGen<Sym>

    let syms: [Sym]
    let text: String

    init(text: String, syms: [Sym]) {
        self.text = text
        self.syms = syms
    }

    func generate() -> Generator {
        return Generator(text: text, syms: syms)
    }

}

struct LexerGen<Sym: LexSym>: GeneratorType {

    typealias Element = LexToken<Sym>

    let syms: [Sym]
    let text: String
    var offset = 0

    init(text: String, syms: [Sym]) {
        self.text = text
        self.syms = syms
    }

    mutating func next() -> Element? {
        var ret: Element? = nil

        let startIndex = text.startIndex.advancedBy(offset)
        let rest = text.substringFromIndex(startIndex)

        for sym in syms {
            let len = sym.match(rest)
            if  len > 0 {
                offset += len
                let endIndex = startIndex.advancedBy(len)
                ret = Element(sym: sym, range: Range<String.Index>(start: startIndex, end: endIndex))
                break
            }
        }

        return ret
    }

}
