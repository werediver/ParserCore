import Foundation

protocol BacktrackingParser {

    typealias NTS: NonTerminalSymbol

    func enter(sym: NTS)
    func leave(match: Bool)

    func accept(sym: NTS.TS) -> Bool

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

    case Finish(GenericTreeNode<CommonToken<NTS>>, Bool)

    // TODO: Move to an extension.
    // TODO: Print tokens' source text fragments (find a way to).
    static func debug() -> (a: ParserAction<NTS>, p: Parser<NTS>) -> () {
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

final class Parser<NTS: NonTerminalSymbol>: BacktrackingParser, ActionProducer {

    typealias Action = ParserAction<NTS>

    var onAction: ((Action, sender: Parser) -> ())?

    typealias SrcToken = TextToken<NTS.TS>
    typealias OutToken = CommonToken<NTS>

    let startSym: NTS
    let src: [SrcToken]

    /// Parse tree stack.
    var stack = [GenericTreeNode<OutToken>]()
    var offset: Int? { return stack.last?.value.end } // For convenience

    init(sym: NTS, src: [SrcToken]) {
        self.startSym = sym
        self.src = src

        self.parent = nil
        self.tag = nil
    }

    func parse() -> Bool {
        return startSym.parse(self)
    }

    func enter(sym: NTS) {
        if let child = child {
            child.enter(sym)
        } else {
            let offset = stack.last?.value.end ?? 0
            stack.append(GenericTreeNode(OutToken(sym: sym, start: offset)))
            onAction?(.Enter(sym), sender: self)
        }
    }

    func leave(match: Bool) {
        if let child = child {
            child.leave(match)
        } else {
            let node = stack.popLast()!
            if match && !stack.isEmpty {
                let parentNode = stack.last!
                parentNode.value.end = node.value.end
                parentNode.children.append(node)
            }
            onAction?(.Leave(node.value.sym, match), sender: self)
            if stack.isEmpty { // False Finish-events possible! (fork the parser!)
                onAction?(.Finish(node, match), sender: self)
            }
        }
    }

    func accept(sym: NTS.TS) -> Bool {
        if let child = child {
            return child.accept(sym)
        } else {
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

    // MARK: - Fork support

    var child: Parser?
    weak var parent: Parser?
    let tag: String?

    private init(parentParser: Parser<NTS>, tag: String) {
        self.parent = parentParser
        self.tag = tag

        let parentToken = parentParser.stack.last!.value

        self.startSym = parentToken.sym
        self.src = parentParser.src
        // The forked parser will continue to build the parent node.
        self.stack = [GenericTreeNode(OutToken(sym: parentToken.sym, start: parentToken.end))]
    }

    func fork(tag: String) {
        if let child = child {
            child.fork(tag)
        } else {
            child = Parser(parentParser: self, tag: tag)
        }
    }

    func unfork(match: Bool) {
        if let child = child {
            child.unfork(match)
        } else {
            let parent = self.parent!
            if match {
                let node = stack.popLast()!
                parent.stack.last?.children.appendContentsOf(node.children)
            }
            parent.child = nil
        }
    }

}
