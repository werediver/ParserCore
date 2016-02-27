import Foundation

protocol BacktrackingParser {

    typealias NTS: NonTerminalSymbol

    func enter(s: NTS)
    func leave(match: Bool)

    func accept(s: NTS.TS) -> Bool

}

protocol NonTerminalSymbol {

    typealias TS: TerminalSymbol

    func parse<Parser: BacktrackingParser where Parser.NTS == Self>(p: Parser) -> Bool

}

enum ParserAction<NTS: NonTerminalSymbol> {

    typealias TS = NTS.TS

    case Enter(NTS)
    case Leave(NTS, Bool)

    case Accept(TS, Bool)

    case Finish(TreeNode<Token<NTS, Int>>, Bool)

    // TODO: Move to an extension.
    // TODO: Print tokens' source text fragments (find a way to).
    static func debug() -> (p: Parser<NTS>, a: ParserAction<NTS>) -> () {
        let indent = "    "
        var indentLevel = 0
        return { p, a in
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
                    print("overall match: \(match)\n\(tree.dump(.Indent))")
            }
        }
    }

}

class Parser<NTS: NonTerminalSymbol>: BacktrackingParser {

    typealias Action = ParserAction<NTS>

    var onAction: ((Parser<NTS>, Action) -> ())?

    let startSym: NTS
    let src: [Token<NTS.TS, String.Index>]

    var stack = [TreeNode<Token<NTS, Int>>]()
    var offset: Int? { return stack.last?.value.end } // For convenience

    init(sym: NTS, src: [Token<NTS.TS, String.Index>]) {
        self.startSym = sym
        self.src = src
    }

    func parse() -> Bool {
        // TODO: Fork the parser!
        return startSym.parse(self)
    }

    func enter(sym: NTS) {
        let offset = stack.last?.value.end ?? 0
        stack.append(TreeNode(Token(sym: sym, start: offset)))
        onAction?(self, .Enter(sym))
    }

    func leave(match: Bool) {
        let node = stack.popLast()!
        if match && !stack.isEmpty {
            let parentNode = stack.last!
            parentNode.value.end = node.value.end
            parentNode.childs.append(node)
        }
        onAction?(self, .Leave(node.value.sym, match))
        if stack.isEmpty { // False Finish-events possible! (fork the parser!)
            onAction?(self, .Finish(node, match))
        }
    }

    func accept(sym: NTS.TS) -> Bool {
        let node = stack.last!
        let match: Bool
        if node.value.end < src.count && src[node.value.end].sym == sym {
            node.value.end += 1
            match = true
        } else {
            match = false
        }
        onAction?(self, .Accept(sym, match))
        return match
    }

}
