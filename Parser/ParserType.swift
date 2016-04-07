import Foundation

protocol ParserType {

    associatedtype NonTerminalSymbol: NonTerminalSymbolType
    associatedtype Source: CollectionType // [NonTerminalSymbol.SourceSymbol]

    associatedtype Token: TokenType // GenericToken<NonTerminalSymbol, Source.Index>
    associatedtype Node: TreeNodeType // GenericTreeNode<Token>

    var src: Source { get }
    var tree: Node? { get }

    init(_: NonTerminalSymbol.Type, src: Source)

    func enterSym(sym: NonTerminalSymbol)
    func leaveSym(match match: Bool)

    func enterGroup()
    func leaveGroup(match match: Bool)

    func accept(sym: NonTerminalSymbol.SourceSymbol) -> Bool

}

extension ParserType {

    func parse() -> Bool {
        return parse(NonTerminalSymbol.startSymbol)
    }

    func parse(sym: NonTerminalSymbol) -> Bool {
        return sym.parse(self)
    }

    func parse(sym: NonTerminalSymbol, @noescape body: () throws -> Bool) rethrows -> Bool {
        enterSym(sym)
        let match = try body()
        leaveSym(match: match)
        return match
    }

    func parse(@noescape body: () throws -> Bool) rethrows -> Bool {
        enterGroup()
        let match = try body()
        leaveGroup(match: match)
        return match
    }

    func parseOpt(@noescape body: () throws -> Bool) rethrows -> Bool {
        try parse(body)
        return true
    }

    func parse(@noescape body: () throws -> Bool, times: Range<Int>) rethrows -> Bool {
        var n = 0
        enterGroup()
        while try n < times.endIndex && parse(body) {
            n += 1
        }
        let match = times.contains(n)
        leaveGroup(match: match)
        return match
    }

    func parseZeroOrMore(@noescape body: () throws -> Bool) rethrows -> Bool {
        return try parse(body, times: 0 ..< Int.max)
    }

    func parseOneOrMore(@noescape body: () throws -> Bool) rethrows -> Bool {
        return try parse(body, times: 1 ..< Int.max)
    }

}
