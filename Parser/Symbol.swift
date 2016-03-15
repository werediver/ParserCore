import Foundation

protocol Symbol {

    var symbolName: String { get }

}

func ==(lhs: Symbol, rhs: Symbol) -> Bool {
    return lhs.symbolName == rhs.symbolName
}

protocol TerminalSymbol: Symbol {

    typealias Source

    func match(src: Source) -> Int

}

protocol NonTerminalSymbol: Symbol {

    typealias SourceSymbol: TerminalSymbol

    func parse<Parser: BacktrackingParser>(p: Parser) -> Bool

}
