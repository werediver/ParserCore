import Foundation

protocol Symbol {

    var symbolName: String { get }

    func isEqual(sym: Symbol) -> Bool

}

extension Symbol {

    var symbolName: String { return "\(self)" }

    func isEqual(sym: Symbol) -> Bool {
        return symbolName == sym.symbolName
    }

}

func ==<S: Symbol>(lhs: S, rhs: S) -> Bool {
    return lhs.isEqual(rhs)
}

protocol TerminalSymbol: Symbol {

    typealias Source: CollectionType

    func match(src: Source.SubSequence) -> Source.Index.Distance

    static var all: [Self] { get }

}

protocol NonTerminalSymbol: Symbol {

    typealias SourceSymbol: TerminalSymbol

    static var startSymbol: Self { get }

    func parse<Parser: ParserType where Parser.NTS == Self>(p: Parser) -> Bool

}
