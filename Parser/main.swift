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

enum ShallowMathNTS: NonTerminalSymbol {

    typealias SourceSymbol = MathTS

    case S, P, T

    static var startSymbol: ShallowMathNTS { return .S }

    func parse<Parser: ParserType where Parser.NTS == ShallowMathNTS>(p: Parser) -> Bool {
        return p.parseSym(self) {
            switch self {
                case S:
                    return P.parse(p) && p.parseZeroOrMore { p.acceptSym(.AddTierOp) && P.parse(p) }
                case P:
                    return T.parse(p) && p.parseZeroOrMore { p.acceptSym(.MulTierOp) && T.parse(p) }
                case T:
                    return p.parse { p.acceptSym(.ParOp) && S.parse(p) && p.acceptSym(.ParCl) }
                        || p.parse { p.acceptSym(.Num) }
            }
        }
    }

}

let src = "(1 + 2 + 3 * 4 * 5) * 6 + 7x"
let lexer = Lexer<MathTS>(src: src)
let tss = lexer.filter { $0.sym != .Space }
//print(tss)
//let p = Parser(DeepMathNTS.self, src: tss)
let p = Parser(ShallowMathNTS.self, src: tss)
let tree = p.parse()
//print(tree?.treeDescription(includePath: false) ?? "Invalid input")
print(tree?.treeDescription(includePath: false, description: { node in
    var s = "\(node.value.sym)"
    if node.children.count == 0 {
        s += " (" + tss[node.value.range].map(lexer.tokenDescription).joinWithSeparator(" ") + ")"
    }
    return s
}) ?? "Invalid input")
