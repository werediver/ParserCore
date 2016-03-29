import Foundation

protocol ParserType {

    associatedtype NTS: NonTerminalSymbolType
    associatedtype Source: CollectionType // [NTS.SourceSymbol]

    associatedtype Token: TokenType // GenericToken<NTS, Source.Index>
    associatedtype Node: TreeNodeType // GenericTreeNode<Token>

    var src: Source { get }
    var tree: Node? { get }

    init(_: NTS.Type, src: Source)

    func enterSym(sym: NTS)
    func leaveSym(match match: Bool)

    func enterGroup()
    func leaveGroup(match match: Bool)

    func accept(sym: NTS.SourceSymbol) -> Bool

}

extension ParserType {

    func parse() -> Bool {
        return parse(NTS.startSymbol)
    }

    func parse(sym: NTS) -> Bool {
        return sym.parse(self)
    }

    func parse(sym: NTS, @noescape body: () throws -> Bool) rethrows -> Bool {
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

class Parser<NTS: NonTerminalSymbolType, Source: CollectionType
    where Source.Generator.Element: TokenType,
          Source.Generator.Element.Symbol == NTS.SourceSymbol,
          Source.Index == Int>: ParserType
{

    typealias Token = GenericToken<NTS, Source.Index>
    typealias Node = GenericTreeNode<Token>

    var parseTreeStack = [Node]()
    var parseTreeStackRestorePoints = [Int]()

    let src: Source
    var tree: Node? { return parseTreeStack.first }

    required init(_: NTS.Type, src: Source) {
        self.src = src
    }

    func enterSym(sym: NTS) {
        let offset = parseTreeStack.last?.value.end ?? 0
        parseTreeStack.append(Node(Token(sym: sym, start: offset)))
    }

    func leaveSym(match match: Bool) {
        let node = parseTreeStack.popLast()!
        if match {
            if parseTreeStack.isEmpty {
                if node.value.end == src.endIndex {
                    parseTreeStack.append(node) // Keep the final result.
                }
            } else {
                let parentNode = parseTreeStack.last!
                parentNode.value.end = node.value.end
                parentNode.children.append(node)
            }
        }
    }

    func enterGroup() {
        let restorePoint = parseTreeStack.endIndex
        parseTreeStackRestorePoints.append(restorePoint)

        let continuationNode = parseTreeStack.last!
        parseTreeStack.append(Node(continuationNode.value))
    }

    func leaveGroup(match match: Bool) {
        let restorePoint = parseTreeStackRestorePoints.popLast()!
        if match {
            assert(restorePoint.distanceTo(parseTreeStack.endIndex) == 1)
            let node = parseTreeStack[restorePoint - 1]
            let continuationNode = parseTreeStack[restorePoint]
            //assert(node.value == continuationNode.value) // Tokens are not generally `Equatable`.
            assert(node.value.start == continuationNode.value.start)
            node.value = continuationNode.value
            node.children.appendContentsOf(continuationNode.children)
            parseTreeStack.removeLast()
        } else {
            parseTreeStack.removeRange(restorePoint ..< parseTreeStack.endIndex)
        }
    }

    func accept(sym: NTS.SourceSymbol) -> Bool {
        let node = parseTreeStack.last!
        let match: Bool
        if node.value.end < src.count && src[node.value.end].sym == sym {
            node.value.end += 1
            match = true
        } else {
            match = false
        }
        return match
    }

}
