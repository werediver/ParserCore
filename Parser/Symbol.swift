import Foundation

protocol SymbolType: Equatable {

    var symbolName: String { get }

}

extension SymbolType {

    var symbolName: String { return "\(self)" }

}

func ==<S: SymbolType>(lhs: S, rhs: S) -> Bool {
    return lhs.symbolName == rhs.symbolName
}

protocol TerminalSymbolType: SymbolType {

    associatedtype Source: CollectionType

    func match(tail: Source.SubSequence) -> Source.Index.Distance

    static var all: [Self] { get }

}

protocol NonTerminalSymbolType: SymbolType {

    associatedtype SourceSymbol: TerminalSymbolType

    func parse<Parser: ParserType where Parser.TargetSymbol == Self>(p: Parser) -> Bool

    static var startSymbol: Self { get }

}
