import ParserCore
import RegEx

extension JSONParser {

    static func numberLiteral() -> Parser<Double> {

        let minus = Core.subseq("-").map(String.init)
        let sign  = Core.oneOf(["-", "+"].map(Character.init)).map(String.init)
        let floatingPointE = Core.oneOf(["e", "E"].map(Character.init)).map(String.init)
        let decimalSeparator = Core.subseq(".").map(String.init)
        let decimalDigits  = Core.string(charset: Charset.digits, count: .atLeast(1))
        let decimalNumber = Core.oneOf(
                Core.subseq("0").map(String.init),
                Core.string(charset: Charset.nonZeroDigits, count: .exactly(1))
                    .flatMap { (firstDigit: String) -> Parser<String> in
                        Core.string(charset: Charset.digits, count: .atLeast(0))
                            .map { restDigits in firstDigit + restDigits }
                    }
            )
        let decimalExponent = Core.maybe(floatingPointE)
            .flatMap { (e: String?) -> Parser<String> in
                Core.maybe(sign)
                .flatMap { (sign: String?) in
                    decimalDigits
                        .map { (exp: String) -> String in
                            [e, sign, exp]
                                .compactMap(id)
                                .joined()
                        }
                }
            }

        return leadingWhitespace <|
            tag("NUMBER") <|
            Core.maybe(minus)
                .flatMap { (minus: String?) -> Parser<String> in
                    decimalNumber
                        .flatMap { (naturalPart: String) -> Parser<String> in
                            Core.maybe(
                                    decimalSeparator
                                        .flatMap { (decimalSeparator: String) -> Parser<String> in
                                            decimalDigits
                                                .map { fractionalPart in
                                                    [decimalSeparator, fractionalPart]
                                                        .joined()
                                                }
                                        }
                                )
                                .flatMap { (dotFractionalPart: String?) -> Parser<String> in
                                    Core.maybe(decimalExponent)
                                        .map { (exponent: String?) -> String in
                                            [minus, naturalPart, dotFractionalPart, exponent]
                                                .compactMap(id)
                                                .joined()
                                        }
                                }
                        }
                }
                .attemptMap { text -> Either<Mismatch, Double> in
                    Double(text)
                        .map(Either.right)
                    ??  .left(Mismatch(tag: "NUMBER", expectation: .text("double precision floating point number")))
                }
    }
}
