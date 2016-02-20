import Foundation

/*

S -> P | P "+" S
P -> T | T "*" P
T -> N | "(" S ")"

The following will produce more shallow tree and move the associativity question to semantic level.

S -> P ( "+" P )*
P -> T ( "*" T )*
T -> N | "(" S ")"

*/

enum MathTS: RegEx, TerminalSymbol {

    case Space = "^\\s+"
    case Num = "^\\d+"
    case AddTierOp = "^[+-]"
    case MulTierOp = "^[*/]"
    case ParOp = "^\\("
    case ParCl = "^\\)"

    static let all: [MathTS] = [.Space, .Num, .AddTierOp, .MulTierOp, .ParOp, .ParCl]

}

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

let src = "(1 + 2 + 3 * 4 * 5) * 6 + 7"
let tks = Lexer(syms: MathTS.all, src: src).filter { $0.sym != MathTS.Space } .map { $0 }
let p = Parser(startSym: MathNTS.S, src: tks)
p.onAction = ParserAction<MathNTS>.debug()
p.parse()
