import Foundation

protocol ParserType {

    typealias NTS: NonTerminalSymbol
    typealias Source: CollectionType

    init(_: NTS.Type, src: Source)

    func enterSym(sym: NTS)
    func leaveSymWithMatch(match: Bool)

    func acceptSym(sym: NTS.SourceSymbol) -> Bool

    func pushState()
    func popState(merge: Bool)

}

extension ParserType {

    func parseSym(sym: NTS, @noescape body: () throws -> Bool) rethrows -> Bool {
        enterSym(sym)
        let match = try body()
        leaveSymWithMatch(match)
        return match
    }

    func parse(@noescape body: () throws -> Bool) rethrows -> Bool {
        pushState()
        let match = try body()
        popState(match)
        return match
    }

    func parseOpt(@noescape body: () throws -> Bool) rethrows -> Bool {
        try parse(body)
        return true
    }

    func parse(@noescape body: () throws -> Bool, times: Range<Int>) rethrows -> Bool {
        var n = 0
        pushState()
        while try n < times.endIndex && parse(body) {
            n += 1
        }
        let match = times.contains(n)
        popState(match)
        return match
    }

    func parseZeroOrMore(@noescape body: () throws -> Bool) rethrows -> Bool {
        return try parse(body, times: 0 ..< Int.max)
    }

    func parseOneOrMore(@noescape body: () throws -> Bool) rethrows -> Bool {
        return try parse(body, times: 1 ..< Int.max)
    }

}

class Parser<NTS: NonTerminalSymbol, Source: CollectionType
    where Source.Generator.Element: TokenType,
          Source.Generator.Element.Symbol == NTS.SourceSymbol,
          Source.Index == Int>: ParserType
{

    typealias Token = GenericToken<NTS, Source.Index>
    typealias Node = GenericTreeNode<Token>

    var parseTreeStack = [Node]()
    var parseTreeStackRestorePoints = [Int]()

    let src: Source

    required init(_: NTS.Type, src: Source) {
        self.src = src
    }

    func parse() -> Node? {
        return parse(NTS.startSymbol)
    }

    func parse(sym: NTS) -> Node? {
        sym.parse(self)
        return parseTreeStack.first
    }

    func enterSym(sym: NTS) {
        let offset = parseTreeStack.last?.value.end ?? 0
        parseTreeStack.append(Node(Token(sym: sym, start: offset)))
    }

    func leaveSymWithMatch(match: Bool) {
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

    func acceptSym(sym: NTS.SourceSymbol) -> Bool {
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

    func pushState() {
        let restorePoint = parseTreeStack.count
        parseTreeStackRestorePoints.append(restorePoint)

        let continuationNode = parseTreeStack.last!
        parseTreeStack.append(Node(continuationNode.value))
    }

    func popState(merge: Bool) {
        let restorePoint = parseTreeStackRestorePoints.popLast()!
        if merge {
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

}
