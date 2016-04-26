import Foundation

class Parser<NonTerminalSymbol: NonTerminalSymbolType, Source: CollectionType
    where Source.Generator.Element: TokenType,
          Source.Generator.Element.SymbolType == NonTerminalSymbol.SourceSymbol,
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

    func push(sym: NonTerminalSymbol) {
        let offset = stack.last?.value.range.endIndex ?? 0
        stack.append(Node(Token(sym: sym, range: offset ..< offset)))
    }

    func push() {
        let restorePoint = stack.endIndex
        restorePoints.append(restorePoint)

        let continuationNode = stack.last!
        stack.append(Node(continuationNode.value))
    }

    func pop(match match: Bool) {
        let node = stack.popLast()!
        let head = stack.last
        if match {
            if let head = head {
                if head.value.sym == node.value.sym
                && head.value.range.startIndex == node.value.range.endIndex
                {
                    head.value = node.value
                    head.children.appendContentsOf(node.children)
                } else {
                    head.value.range.endIndex = node.value.range.endIndex
                    head.children.append(node)
                }
            } else if node.value.range.endIndex == src.endIndex {
                stack.append(node) // Keep the final result.
            }
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
