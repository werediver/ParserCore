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

extension BacktrackingParser {

    func parse(sym: NTS, alts: (() -> Bool)...) -> Bool {
        for alt in alts {
            enter(sym)
            let match = alt()
            leave(match)
            if match {
                return true
            }
        }
        return false
    }

}

enum MathNTS: NonTerminalSymbol {

    typealias TS = MathTS

    case S, P, T

    func parse<Parser : BacktrackingParser where Parser.NTS == MathNTS>(p: Parser) -> Bool {
        switch self {
            case .S:
                return p.parse(.S, alts:
                    { MathNTS.P.parse(p) && p.accept(.AddTierOp) && MathNTS.S.parse(p) },
                    { MathNTS.P.parse(p) }
                )
            case .P:
                return p.parse(.P, alts:
                    { MathNTS.T.parse(p) && p.accept(.MulTierOp) && MathNTS.P.parse(p) },
                    { MathNTS.T.parse(p) }
                )
            case .T:
                return p.parse(.T, alts:
                    { p.accept(.ParOp) && MathNTS.S.parse(p) && p.accept(.ParCl) },
                    { p.accept(.Num) }
                )
        }
    }

}

let src = "(1 + 2 + 3 * 4 * 5) * 6 + 7"
print("Input: \"\(src)\"")
let tks = Lexer(syms: MathTS.all, src: src).filter { $0.sym != MathTS.Space } .map { $0 }
let p = Parser(sym: MathNTS.S, src: tks)
p.onAction = ParserAction<MathNTS>.debug()
p.parse()
