import Foundation

protocol BacktrackingParser {

    func enter(sym: Symbol)
    func leave(match: Bool)

    func accept(sym: Symbol) -> Bool

}

enum ParserAction {

    case Enter(Symbol)
    case Leave(Symbol, Bool)

    case Accept(Symbol, Bool)

    case Finish(GenericTreeNode<CommonToken<Symbol>>, Bool)

    // TODO: Move to an extension.
    // TODO: Print tokens' source text fragments (find a way to).
    static func debug<SrcToken>() -> (a: ParserAction, p: Parser<SrcToken>) -> () {
        let indent = "    "
        var indentLevel = 0
        return { a, p in
            func p(s: String) {
                print(indent.mul(indentLevel) + (p.offset != nil ? "\(p.offset!): " : "" ) + s)
            }
            switch a {
                case let .Enter(nts):
                    p("<\(nts)>")
                    indentLevel += 1
                case let .Leave(nts, match):
                    indentLevel -= 1
                    p("</\(nts)> (match: \(match))")
                case let .Accept(ts, match):
                    p((match ? "found: " : "expected: ") + "\(ts)")
                case let .Finish(tree, match):
                    print("overall match: \(match)\n\(tree.treeDescription(includePath: false))")
            }
        }
    }

}

final class Parser<SrcToken: Token where SrcToken.Symbol: Symbol>: BacktrackingParser, ActionProducer {

    typealias Action = ParserAction

    var onAction: ((Action, sender: Parser) -> ())?

    let src: [SrcToken]

    typealias OutToken = CommonToken<Symbol>

    /// Parse tree stack.
    var stack = [GenericTreeNode<OutToken>]()
    var offset: Int? { return stack.last?.value.end } // For convenience

    init(src: [SrcToken]) {
        self.src = src
    }

    func enter(sym: Symbol) {
        let offset = stack.last?.value.end ?? 0
        stack.append(GenericTreeNode(OutToken(sym: sym, start: offset)))
        onAction?(.Enter(sym), sender: self)
    }

    func leave(match: Bool) {
        let node = stack.popLast()!
        if match && !stack.isEmpty {
            let parentNode = stack.last!
            parentNode.value.end = node.value.end
            parentNode.children.append(node)
        }
        onAction?(.Leave(node.value.sym, match), sender: self)
        if stack.isEmpty { // False Finish-events possible!
            onAction?(.Finish(node, match), sender: self)
        }
    }

    func accept(sym: Symbol) -> Bool {
        let node = stack.last!
        let match: Bool
        if node.value.end < src.count && src[node.value.end].sym == sym {
            node.value.end += 1
            match = true
        } else {
            match = false
        }
        onAction?(.Accept(sym, match), sender: self)
        return match
    }

}
