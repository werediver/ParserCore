import Foundation

enum MathTS: RegEx, TerminalSymbol {

    case Space = "^\\s+"
    case Num = "^\\d+"
    case AddTierOp = "^[+-]"
    case MulTierOp = "^[*/]"
    case ParOp = "^\\("
    case ParCl = "^\\)"

    static let all: [MathTS] = [.Space, .Num, .AddTierOp, .MulTierOp, .ParOp, .ParCl]

}

/*
for token in lexer {
    if token.sym == .Space { continue }
    print(token)
}
*/

/*

S -> P | P "+" S
P -> T | T "*" P
T -> N | "(" S ")"

The following will produce more shallow tree and move the associativity question to semantic level.

S -> P ( "+" P )*
P -> T ( "*" T )*
T -> N | "(" S ")"

*/

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

class Parser<_NTS: NonTerminalSymbol>: BacktrackingParser {

    typealias NTS = _NTS

    typealias Action = ParserAction<NTS>

    var onAction: ((Parser<NTS>, Action) -> ())?

    let src: [Token<NTS.TS, String.Index>]

    let startSym: NTS

    var stack = [TreeNode<Token<NTS, Int>>]()
    var offset: Int? { return stack.last?.value.end }

    init(startSym: NTS, src: [Token<NTS.TS, String.Index>]) {
        self.startSym = startSym
        self.src = src
    }

    func parse() -> Bool {
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
        if stack.isEmpty {
            onAction?(self, .Finish(node, match)) // NB! This may not be the very final point!
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

/*
S -> P | P "+" S
P -> T | T "*" P
T -> N | "(" S ")"
*/
enum MathNTS: NonTerminalSymbol {

    typealias TS = MathTS

    case S, P, T

    func parse<Parser : BacktrackingParser where Parser.NTS == MathNTS>(p: Parser) -> Bool {
        switch self {
            case .S:
                p.enter(.S)
                let match = MathNTS.P.parse(p) && p.accept(.AddTierOp) && MathNTS.S.parse(p)
                p.leave(match)
                if match {
                    return true
                } else {
                    p.enter(.S)
                    let match = MathNTS.P.parse(p)
                    p.leave(match)
                    if match {
                        return true
                    }
                }
            case .P:
                p.enter(.P)
                let match = MathNTS.T.parse(p) && p.accept(.MulTierOp) && MathNTS.P.parse(p)
                p.leave(match)
                if match {
                    return true
                } else {
                    p.enter(.P)
                    let match = MathNTS.T.parse(p)
                    p.leave(match)
                    if match {
                        return true
                    }
                }
            case .T:
                p.enter(.T)
                let match = p.accept(.ParOp) && MathNTS.S.parse(p) && p.accept(.ParCl)
                p.leave(match)
                if match {
                    return true
                } else {
                    p.enter(.T)
                    let match = p.accept(.Num)
                    p.leave(match)
                    if match {
                        return true
                    }
                }
        }
        return false
    }

}

//let src = "(1 + 2 + 3 * 4 * 5) * 6 + 7"
let src = "1+2"
let tks = Lexer(syms: MathTS.all, src: src).map { $0 }
let p = Parser(startSym: MathNTS.S, src: tks)
p.onAction = ParserAction<MathNTS>.debug()
p.parse()

/*

// TODO: Introduce delegate. Extract all debug output to some debug delegate.

class Parser<InSym: Equatable, OutSym> {

    var outStack = [Token<OutSym, Int>]() {
        didSet {
            indent = (0 ..< outStack.count) .reduce("") { s, _ in s + "  " }
        }
    }
    var out: ParserState! {
        get { return outStack.last }
        set {
            if outStack.count > 0 {
                outStack[outStack.endIndex - 1] = newValue
            } else {
                outStack.append(newValue)
            }
        }
    }

    private(set) var indent: String = ""

    func info(s: String) {
        print(indent + s)
    }

    func enter(tag: String) {
        info("<\(tag)>")
        outStack.append(Token(sym: tag, start: state?.endOffset ?? 0))
    }

    func leave(match: Bool) {
        let _out = outStack.popLast()!
        info("</\(_out.tag)>")
        if match {
            if outStack.count > 0 {
                out.end = _out.endOffset
            } else {
                if ts.count == _out.endOffset {
                    print("Done!")
                } else {
                    print("Fragment parsed.")
                }
            }
        } else {
            if outStack.count <= 0 {
                print("Failed.")
            }
        }
    }

    let ts: [Token<InSym>]
    var t: Token<Sym>? {
        return (state.endOffset < ts.endIndex) ? ts[state.endOffset] : nil
    }

    init(ts: [Token<Sym>]) {
        self.ts = ts
    }

    func accept(sym: Sym) -> Bool {
        if t?.sym == sym {
            info("\(state.endOffset): \(sym)")
            state.endOffset += 1
            return true
        } else {
            info("\(state.endOffset): not \(sym)")
            return false
        }
    }

}

//let ts = Array(Lexer(text: "(1 + 2 + 3 * 4 * 5) * 6 + 7", syms: MathTS.all).filter { $0.sym != .Space })
//print(ts)

var parser = Parser(ts: ts)

func s() -> Bool {
    parser.enter("S")
    var match = false
    if p() {
        if parser.accept(.Add) {
            if s() {
                match = true
            }
        } else {
            match = true
        }
    }
    parser.leave(match)
    return match
}

func p() -> Bool {
    parser.enter("P")
    var match = false
    if t() {
        if parser.accept(.Mul) {
            if p() {
                match = true
            }
        } else {
            match = true
        }
    }
    parser.leave(match)
    return match
}

func t() -> Bool {
    parser.enter("T")
    var match = false
    if parser.accept(.ParOp) {
        if s() {
            if parser.accept(.ParCl) {
                match = true
            }
        }
    } else if parser.accept(.Num) {
        match = true
    }
    parser.leave(match)
    return match
}

s()
*/