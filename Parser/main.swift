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

    typealias Source = String

    case Space = "^\\s+"
    case Num = "^\\d+"
    case AddTierOp = "^[+-]"
    case MulTierOp = "^[*/]"
    case ParOp = "^\\("
    case ParCl = "^\\)"

    static let all: [MathTS] = [.Space, .Num, .AddTierOp, .MulTierOp, .ParOp, .ParCl]

    var symbolName: String { return "\(self)" }

}

extension BacktrackingParser {

    func parse(sym: Symbol, alts: (() -> Bool)...) -> Bool {
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

    typealias SourceSymbol = MathTS

    case S, P, T

    var symbolName: String { return "\(self)" }

    func parse<Parser: BacktrackingParser>(p: Parser) -> Bool {
        switch self {
            case .S:
                return p.parse(MathNTS.S, alts:
                    { MathNTS.P.parse(p) && p.accept(MathTS.AddTierOp) && MathNTS.S.parse(p) },
                    { MathNTS.P.parse(p) }
                )
            case .P:
                return p.parse(MathNTS.P, alts:
                    { MathNTS.T.parse(p) && p.accept(MathTS.MulTierOp) && MathNTS.P.parse(p) },
                    { MathNTS.T.parse(p) }
                )
            case .T:
                return p.parse(MathNTS.T, alts:
                    { p.accept(MathTS.ParOp) && MathNTS.S.parse(p) && p.accept(MathTS.ParCl) },
                    { p.accept(MathTS.Num) }
                )
        }
    }

}

let src = "(1 + 2 + 3 * 4 * 5) * 6 + 7"
print("Input: \"\(src)\"")
let tks = Lexer(syms: MathTS.all, src: src).filter { $0.sym != MathTS.Space } .map { $0 }
let p = Parser(src: tks)
p.onAction = ParserAction.debug()
MathNTS.S.parse(p)
