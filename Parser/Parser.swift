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

final class CommonTokenTreeNode<Symbol>: Token, TreeNode, CustomStringConvertible {

    // MARK: - Token

    typealias Index = Int

    let sym: Symbol

    let start: Index
    var   end: Index

    // Required by `Token` protocol
    convenience init(sym: Symbol, start: Index, end: Index) {
        self.init(sym: sym, start: start, end: end, children: [])
    }

    // MARK: - TreeNode

    weak var parent: CommonTokenTreeNode?

    var children: [CommonTokenTreeNode] {
        didSet {
            updateChildren()
        }
    }

    init(sym: Symbol, start: Index, end: Index, children: [CommonTokenTreeNode]) {
        self.sym = sym
        self.start = start
        self.end = end
        self.children = children
        updateChildren()
    }

    convenience init(sym: Symbol, start: Index, children: [CommonTokenTreeNode] = []) {
        self.init(sym: sym, start: start, end: start, children: children)
    }

    // MARK: - CustomStringConvertible

    var description: String {
        return (sym as? CustomStringConvertible)?.description
            ?? "\(self.dynamicType)" // Fallback, close to the default behaviour.
    }

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

    var onAction: ((Action, sender: Parser<NTS>) -> ())?

    weak var parent: Parser<NTS>?
    let tag: String?

    typealias SrcToken = TextToken<NTS.TS>
    typealias OutToken = CommonToken<NTS>

    let startSym: NTS
    let src: [SrcToken]

    var stack = [GenericTreeNode<OutToken>]()
    var offset: Int? { return stack.last?.value.end } // For convenience

    init(sym: NTS, src: [SrcToken]) {
        self.startSym = sym
        self.src = src

        self.parent = nil
        self.tag = nil
    }

    init(parentParser: Parser<NTS>, tag: String) {
        self.parent = parentParser
        self.tag = tag

        let parentToken = parentParser.stack.last!.value

        self.startSym = parentToken.sym
        self.src = parentParser.src
        // The forked parser will continue to build the parent node.
        self.stack = [GenericTreeNode(OutToken(sym: parentToken.sym, start: parentToken.end))]
    }

    func parse() -> Bool {
        return startSym.parse(self)
    }

    func enter(sym: NTS) {
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
        if stack.isEmpty { // False Finish-events possible! (fork the parser!)
            onAction?(.Finish(node, match), sender: self)
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
        onAction?(.Accept(sym, match), sender: self)
        return match
    }

}
