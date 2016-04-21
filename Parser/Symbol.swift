import Foundation

protocol Symbol: Equatable {

    var symbolName: String { get }

}

extension Symbol {

    var symbolName: String { return "\(self)" }

}

func ==<S: Symbol>(lhs: S, rhs: S) -> Bool {
    return lhs.symbolName == rhs.symbolName
}

protocol TerminalSymbolType: Symbol {

    associatedtype Source: CollectionType

    func match(src: Source.SubSequence) -> Source.Index.Distance

    static var all: [Self] { get }

}

protocol NonTerminalSymbolType: Symbol {

    associatedtype SourceSymbol: TerminalSymbolType

    func parse<Parser: ParserType where Parser.TargetSymbol == Self>(p: Parser) -> Bool

    static var startSymbol: Self { get }

}
