import Foundation

class Parser<NonTerminalSymbol: NonTerminalSymbolType, Source: CollectionType
    where Source.Generator.Element: TokenType,
          Source.Generator.Element.Symbol == NonTerminalSymbol.SourceSymbol,
          Source.Index == Int>: ParserType
{

    typealias Token = GenericToken<NonTerminalSymbol, Source.Index>
    typealias Node = GenericTreeNode<Token>

    var parseTreeStack = [Node]()
    var parseTreeStackRestorePoints = [Int]()

    let src: Source
    var tree: Node? { return parseTreeStack.first }

    required init(_: NonTerminalSymbol.Type, src: Source) {
        self.src = src
    }

    func enterSym(sym: NonTerminalSymbol) {
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

    func accept(sym: NonTerminalSymbol.SourceSymbol) -> Bool {
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
