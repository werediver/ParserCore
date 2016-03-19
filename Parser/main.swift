import Foundation

enum MathTS: RegEx, TerminalSymbol {

    typealias Source = String.CharacterView

    case Space = "\\s+"
    case Num = "\\d+"
    case AddTierOp = "[+-]"
    case MulTierOp = "[*/]"
    case ParOp = "\\("
    case ParCl = "\\)"

    static let all: [MathTS] = [.Space, .Num, .AddTierOp, .MulTierOp, .ParOp, .ParCl]

}

enum DeepMathNTS: NonTerminalSymbol {

    typealias SourceSymbol = MathTS

    case S, P, T

    static var startSymbol: DeepMathNTS { return .S }

    func parse<Parser: ParserType where Parser.NTS == DeepMathNTS>(p: Parser) -> Bool {
        return p.parseSym(self) {
            switch self {
                case S:
                    return P.parse(p) && p.parseOpt { p.acceptSym(.AddTierOp) && S.parse(p) }
                case P:
                    return T.parse(p) && p.parseOpt { p.acceptSym(.MulTierOp) && P.parse(p) }
                case T:
                    return p.parse { p.acceptSym(.ParOp) && S.parse(p) && p.acceptSym(.ParCl) }
                        || p.parse { p.acceptSym(.Num) }
            }
        }
    }

}

let src = "(1 + 2 + 3 * 4 * 5) * 6 + 7x"
let tks = Lexer<MathTS>(src: src).filter { $0.sym != .Space }
//print(tks)
let p = Parser(DeepMathNTS.self, src: tks)
let tree = p.parse()
print(tree?.treeDescription(includePath: false) ?? "Invalid input")
