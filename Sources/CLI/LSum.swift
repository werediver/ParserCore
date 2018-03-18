import Foundation
import ParserCore2

// START <- LSUM END
//
// LSUM  <- LSUM PLUS NUM
//        / NUM
//
// NUM   <- [0-9]+
//
// PLUS  <- "+"

final class LSum {

    let left: LSum?
    let right: Num

    init(left: LSum?, right: Num) {
        self.left = left
        self.right = right
    }
}

final class Num {

    let value: Int

    init(value: Int) {
        self.value = value
    }
}

final class Plus {}

enum LSumParser<Core: SomeCore> where
    Core.Source == String
{
    typealias Parser<Symbol> = GenericParser<Core, Symbol>

    static func start() -> Parser<LSum> {
        return lsum()
            .flatMap { lsum in
                Core.end()
                    .map(const(lsum))
            }
    }

    static func lsum() -> Parser<LSum> {
        return GenericParser { this, _ in
            Core.oneOf(tag: "LSum",
                this.flatMap { lsum in
                        LSumParser.plus()
                            .flatMap { _ in LSumParser.num() }
                            .map { num in
                                LSum(left: lsum, right: num)
                            }
                    },
                LSumParser.num()
                    .map { num in LSum(left: nil, right: num) }
            )
        }
    }

    static func num() -> Parser<Num> {
        return Core.string(charset: digits)
            .attemptMap(tag: "Num") { text in
                Int(text)
                    .map(Num.init)
                    .map(Either.right)
                ??  .left(Mismatch(message: "Invalid integer number: \"\(text)\""))
            }
    }

    static func plus() -> Parser<Plus> {
        return Core.string("+").map(tag: "Plus") { _ in Plus() }
    }
}

private let digits = CharacterSet(charactersIn: "0123456789")
