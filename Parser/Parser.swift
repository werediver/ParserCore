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

enum ParserSym<NTS> {

    case General(NTS)
    case Service(String)

    var generalSym: NTS? {
        switch self {
            case let .General(sym):
                return sym
            default:
                return nil
        }
    }

    var serviceSym: String? {
        switch self {
            case let .Service(sym):
                return sym
            default:
                return nil
        }
    }

}

class Parser<_NTS: NonTerminalSymbol>: BacktrackingParser {

    typealias NTS = _NTS

    typealias Action = ParserAction<NTS>

    let __START = "__START"

    var onAction: ((Parser<NTS>, Action) -> ())?

    let startSym: NTS
    let src: [Token<NTS.TS, String.Index>]

    var stack = [TreeNode<Token<ParserSym<NTS>, Int>>]()
    var offset: Int? { return stack.last?.value.end } // For convenience

    init(startSym: NTS, src: [Token<NTS.TS, String.Index>]) {
        self.startSym = startSym
        self.src = src
    }

    func parse() -> Bool {
        /* TODO: Wrap the `startSym` to accommodate possible root-level alternatives and suppress false Finish events.
        enter("__START")
        let match = startSym.parse(self)
        leave(match)
        return match
        */
        // TODO: Fork the parser!

        //return startSym.parse(self)
        stack.append(TreeNode(Token(sym: .Service(__START), start: 0)))
        return startSym.parse(self)
    }

    func enter(sym: NTS) {
        let offset = stack.last?.value.end ?? 0
        stack.append(TreeNode(Token(sym: .General(sym), start: offset)))
        onAction?(self, .Enter(sym))
    }

    func leave(match: Bool) {
        let node = stack.popLast()!
        if match && !stack.isEmpty {
            let parentNode = stack.last!
            parentNode.value.end = node.value.end
            parentNode.childs.append(node)
        }
        if let sym = node.value.sym.generalSym {
            onAction?(self, .Leave(node.value.sym, match))
        }
        //if stack.isEmpty {
        if node.value.sym.serviceSym == __START {
            assert(node.childs.count <= 1)
            onAction?(self, .Finish(node.childs.first, match))
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
