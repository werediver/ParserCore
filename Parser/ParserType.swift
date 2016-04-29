import Foundation

protocol ParserType {

    associatedtype TargetSymbol: NonTerminalSymbolType
    associatedtype Token: TokenType // GenericToken<TargetSymbol, Source.Index>
    associatedtype Node: TreeNodeType // GenericTreeNode<Token>

    associatedtype Source: CollectionType // [TargetSymbol.SourceSymbol]

    var src: Source { get }
    var tree: Node? { get }

    init(_: TargetSymbol.Type, src: Source)

    func enter(sym: TargetSymbol)
    func enter()
    func leave(match match: Bool)

    func accept(sym: TargetSymbol.SourceSymbol) -> Bool

}

extension ParserType {

    // TODO: Delete.
    func parse() -> Bool {
        return parse(TargetSymbol.startSymbol)
    }

    // TODO: Delete.
    func parse(sym: TargetSymbol) -> Bool {
        return sym.parse(self)
    }

    // TODO: Delete?
    func parse(sym: TargetSymbol, @noescape body: () throws -> Bool) rethrows -> Bool {
        enter(sym)
        let match = try body()
        leave(match: match)
        return match
    }

    func parse(@noescape body: () throws -> Bool) rethrows -> Bool {
        enter()
        let match = try body()
        leave(match: match)
        return match
    }

    func parseOpt(@noescape body: () throws -> Bool) rethrows -> Bool {
        try parse(body)
        return true
    }

    func parse(@noescape body: () throws -> Bool, times: Range<Int>) rethrows -> Bool {
        enter()
        var n = 0
        while try n + 1 < times.endIndex && parse(body) {
            n += 1
        }
        let match = times.contains(n)
        leave(match: match)
        return match
    }

    func parseZeroOrMore(@noescape body: () throws -> Bool) rethrows -> Bool {
        return try parse(body, times: 0 ..< Int.max)
    }

    func parseOneOrMore(@noescape body: () throws -> Bool) rethrows -> Bool {
        return try parse(body, times: 1 ..< Int.max)
    }

}
