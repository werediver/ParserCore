import Foundation

enum MathLexSym: RegEx, LexSym {

    case Space = "^\\s+"
    case Num = "^\\d+"
    case Add = "^[+-]"
    case Mul = "^[*/]"
    case ParOp = "^\\("
    case ParCl = "^\\)"

    static let all: [MathLexSym] = [.Space, .Num, .Add, .Mul, .ParOp, .ParCl]

    func match(s: String) -> Int {
        return rawValue.rangeOfFirstMatchInString(s)?.count ?? 0
    }

}

/*
for token in Lexer(text: "1 + 2 + 3", syms: MathLexSym.all) {
    if token.sym == .Space { continue }
    print(token)
}
*/

/*

S -> P | P + S
P -> T | T * P
T -> N | ( S )

*/

struct ParserState {

    let tag: String
    let startOffset: Int // Range
    var endOffset: Int

    init(tag: String, startOffset: Int) {
        self.tag = tag
        self.startOffset = startOffset
        self.endOffset   = startOffset
    }

}

class Parser<Sym: LexSym where Sym: Equatable> {

    var stateStack = [ParserState]() {
        didSet {
            indent = (0 ..< stateStack.count) .reduce("") { s, _ in s + "  " }
        }
    }
    var state: ParserState! {
        get { return stateStack.last }
        set {
            if stateStack.count > 0 {
                stateStack[stateStack.endIndex - 1] = newValue
            } else {
                stateStack.append(newValue)
            }
        }
    }

    private(set) var indent: String = ""

    func info(s: String) {
        print(indent + s)
    }

    func enter(tag: String) {
        info("<\(tag)>")
        stateStack.append(ParserState(tag: tag, startOffset: state?.endOffset ?? 0))
    }

    func leave(match: Bool) {
        let _state = stateStack.popLast()!
        info("</\(_state.tag)>")
        if match {
            if stateStack.count > 0 {
                state.endOffset = _state.endOffset
            } else {
                if ts.count == _state.endOffset {
                    print("Done!")
                } else {
                    print("Fragment parsed.")
                }
            }
        } else {
            if stateStack.count <= 0 {
                print("Failed.")
            }
        }
    }

    let ts: [LexToken<Sym>]
    var t: LexToken<Sym>? {
        return (state.endOffset < ts.endIndex) ? ts[state.endOffset] : nil
    }

    init(ts: [LexToken<Sym>]) {
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

let ts = Array(Lexer(text: "(1 + 2 + 3 * 4 * 5) * 6 + 7", syms: MathLexSym.all).filter { $0.sym != .Space })
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