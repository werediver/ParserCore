import Foundation

class Parser<NonTerminalSymbol: NonTerminalSymbolType, Source: CollectionType
    where Source.Generator.Element: TokenType,
          Source.Generator.Element.Symbol == NonTerminalSymbol.SourceSymbol,
          Source.Index == Int>: ParserType
{

    typealias Token = GenericToken<NonTerminalSymbol, Source.Index>
    typealias Node = GenericTreeNode<Token>

    /// The Forest of Partial Parse Trees.
    var stack = [Node]()
    var restorePoints = [Int]()

    let src: Source
    var tree: Node? { return stack.first }

    required init(_: NonTerminalSymbol.Type, src: Source) {
        self.src = src
    }

    func enterSym(sym: NonTerminalSymbol) {
        let offset = stack.last?.value.range.endIndex ?? 0
        stack.append(Node(Token(sym: sym, range: offset ..< offset)))
    }

    func leaveSym(match match: Bool) {
        let node = stack.popLast()!
        if match {
            if stack.isEmpty {
                if node.value.range.endIndex == src.endIndex {
                    stack.append(node) // Keep the final result.
                }
            } else {
                let parentNode = stack.last!
                parentNode.value.range.endIndex = node.value.range.endIndex
                parentNode.children.append(node)
            }
        }
    }

    func enterGroup() {
        let restorePoint = stack.endIndex
        restorePoints.append(restorePoint)

        let continuationNode = stack.last!
        stack.append(Node(continuationNode.value))
    }

    func leaveGroup(match match: Bool) {
        let restorePoint = restorePoints.popLast()!
        if match {
            assert(restorePoint.distanceTo(stack.endIndex) == 1)
            let node = stack[restorePoint - 1]
            let continuationNode = stack[restorePoint]
            //assert(node.value == continuationNode.value) // Tokens are not generally `Equatable`.
            assert(node.value.range.startIndex == continuationNode.value.range.startIndex)
            node.value = continuationNode.value
            node.children.appendContentsOf(continuationNode.children)
            stack.removeLast()
        } else {
            stack.removeRange(restorePoint ..< stack.endIndex)
        }
    }

    func accept(sym: NonTerminalSymbol.SourceSymbol) -> Bool {
        let node = stack.last!
        let match: Bool
        if node.value.range.endIndex < src.count && src[node.value.range.endIndex].sym == sym {
            node.value.range.endIndex += 1
            match = true
        } else {
            match = false
        }
        return match
    }

}
