import Foundation

enum MathTS: RegEx, TerminalSymbolType {

    typealias Source = String.CharacterView

    case Space = "\\s+"
    case Num = "\\d+"
    case AddTierOp = "[+-]"
    case MulTierOp = "[*/]"
    case ParOp = "\\("
    case ParCl = "\\)"

    static let all: [MathTS] = [.Space, .Num, .AddTierOp, .MulTierOp, .ParOp, .ParCl]

}

/// Very simple grammar for arithmetic expressions:
///
///     S -> P | P '+' S
///     P -> T | T '*' P
///     T -> '(' S ')' | NUM
///
enum DeepMathNTS: NonTerminalSymbolType {

    typealias SourceSymbol = MathTS

    case S, P, T

    static var startSymbol: DeepMathNTS { return .S }

    func parse<Parser: ParserType where Parser.TargetSymbol == DeepMathNTS>(p: Parser) -> Bool {
        return p.parse(self) {
            switch self {
                case S:
                    return p.parse(.P) && p.parseOpt { p.accept(.AddTierOp) && p.parse(.S) }
                case P:
                    return p.parse(.T) && p.parseOpt { p.accept(.MulTierOp) && p.parse(.P) }
                case T:
                    return p.parse { p.accept(.ParOp) && p.parse(.S) && p.accept(.ParCl) }
                        || p.parse { p.accept(.Num) }
            }
        }
    }

}

/// Very simple grammar for arithmetic expressions:
///
///     S -> P ('+' P)*
///     P -> T ('*' T)*
///     T -> '(' S ')' | NUM
///
enum ShallowMathNTS: NonTerminalSymbolType {

    typealias SourceSymbol = MathTS

    case S, P, T

    static var startSymbol: ShallowMathNTS { return .S }

    func parse<Parser: ParserType where Parser.TargetSymbol == ShallowMathNTS>(p: Parser) -> Bool {
        return p.parse(self) {
            switch self {
                case S:
                    return p.parse(.P) && p.parseZeroOrMore { p.accept(.AddTierOp) && p.parse(.P) }
                case P:
                    return p.parse(.T) && p.parseZeroOrMore { p.accept(.MulTierOp) && p.parse(.T) }
                case T:
                    return p.parse { p.accept(.ParOp) && p.parse(.S) && p.accept(.ParCl) }
                        || p.parse { p.accept(.Num) }
            }
        }
    }

}

func main() -> Int32 {
    let src = "(1 + 2 + 3 * 4 * 5) * 6 + 7"
    let lexer = Lexer<MathTS>(src: src)
    let lexerResults = lexer.map { $0 }

    let errors = lexerResults.filter({ $0.error != nil })
    if  errors.count > 0 {
        print("Lexer reports errors:\n\(errors)")
        return EXIT_FAILURE
    }

    let tks = lexerResults.flatMap { result in result.filter { tk in tk.sym != .Space } }
    //print(tss)
    let p = Parser(DeepMathNTS.self, src: tks)
    //let p = Parser(ShallowMathNTS.self, src: tss)
    p.parse(.startSymbol)

    let desc = p.tree?.treeDescription(includePath: false, description: { node in
        var s = "\(node.value.sym)"
        if node.children.count == 0 {
            s += " (" + tks[node.value.range].map(lexer.tokenDescription).joinWithSeparator(" ") + ")"
        }
        return s
    })
    if let desc = desc {
        print(desc)
        return EXIT_SUCCESS
    } else {
        print("Invalid input")
        return EXIT_FAILURE
    }
}

exit(main())
