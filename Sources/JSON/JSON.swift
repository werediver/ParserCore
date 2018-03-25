import Foundation
import ParserCore
import RegEx

public enum JSON {

    public typealias Object = [String: JSON]

    case object(Object)
    indirect case array([JSON])
    case number(Double)
    case string(String)
    case bool(Bool)
    case null
}

public enum JSONParser<Core: SomeCore> where
    Core.Source == String
{
    public typealias Parser<Symbol> = GenericParser<Core, Symbol>

    typealias Property = (key: String, value: JSON)

    public static func start() -> Parser<JSON> {
        return value()
            .flatMap { value in
                leadingWhitespace <|
                Core.end()
                    .map(const(value))
            }
    }

    static func value() -> Parser<JSON> {
        return Core.oneOf(
                tag: "VALUE",
                objectLiteral().map(JSON.object),
                arrayLiteral().map(JSON.array),
                numberLiteral().map(JSON.number),
                stringLiteral().map(JSON.string),
                boolLiteral().map(JSON.bool),
                null()
            )
    }

    static func objectLiteral() -> Parser<JSON.Object> {
        return leadingWhitespace <|
            tag("OBJECT") <|
            Core.string(tag: "OBJECT_START", "{")
                .flatMap { _ in
                    Core.list(
                            item: property(),
                            separator: leadingWhitespace <| Core.string(",")
                        )
                        .flatMap { properties in
                            leadingWhitespace <|
                            Core.string(tag: "OBJECT_END", "}")
                                .map(const(makeObject(with: properties)))
                        }
                }
    }

    static func makeObject(with properties: [Property]) -> JSON.Object {
        var object = JSON.Object()
        object.reserveCapacity(properties.count)
        properties.forEach { property in object[property.key] = property.value }
        return object
    }

    static func property() -> Parser<Property> {
        return tag("PROPERTY") <|
            stringLiteral()
                .flatMap { name in
                    leadingWhitespace <|
                    Core.string(":")
                        .flatMap { _ in
                            value()
                                .map { value in (name, value) }
                        }
                }
    }

    static func arrayLiteral() -> Parser<[JSON]> {
        return leadingWhitespace <|
            tag("ARRAY") <|
            Core.string(tag: "ARRAY_START", "[")
                .flatMap { _ in
                    Core.list(
                            item: value(),
                            separator: leadingWhitespace <| Core.string(",")
                        )
                        .flatMap { items in
                            leadingWhitespace <|
                            Core.string(tag: "ARRAY_END", "]")
                                .map(const(items))
                        }
                }
    }

    static func _numberLiteral() -> Parser<Double> {
        let numberRegEx = try! RegEx.make("-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?")

        return leadingWhitespace <|
            tag("NUMBER") <|
            Core.string(regex: numberRegEx)
                .attemptMap { firstGroup, _ in
                    Double(firstGroup)
                        .map(Either.right)
                    ??  .left(Mismatch(message: "Cannot create a number from text \"\(firstGroup)\""))
                }
    }

    static func numberLiteral() -> Parser<Double> {
        return leadingWhitespace <|
            tag("NUMBER") <|
            Core.maybe(
                    Core.string("-")
                        .map(String.init)
                )
                .flatMap { (minus: String?) -> Parser<String> in
                    Core.oneOf(
                            Core.string("0").map(String.init),
                            Core.string(charset: Charset.nonZeroDigits, count: .exactly(1))
                                .flatMap { (firstDigit: String) -> Parser<String> in
                                    Core.string(charset: Charset.digits, count: .atLeast(0))
                                        .map { restDigits in firstDigit + restDigits }
                                }
                                .map(String.init)
                        )
                        .flatMap { (naturalPart: String) -> Parser<String> in
                            Core.maybe(
                                Core.string(".")
                                    .map(String.init)
                                    .flatMap { (decimalSeparator: String) -> Parser<String> in
                                        Core.string(charset: Charset.digits, count: .atLeast(1))
                                            .map { fractionalPart in
                                                [decimalSeparator, fractionalPart]
                                                    .joined()
                                            }
                                    }
                                )
                                .flatMap { (dotFractionalPart: String?) -> Parser<String> in
                                    Core.maybe(
                                            Core.maybe(
                                                    Core.oneOf([Character("e"), Character("E")])
                                                        .map(String.init)
                                                )
                                                .flatMap { (e: String?) -> Parser<String> in
                                                    Core.maybe(
                                                        Core.oneOf([Character("-"), Character("+")])
                                                            .map(String.init)
                                                    )
                                                    .flatMap { (sign: String?) in
                                                        Core.string(charset: Charset.digits, count: .atLeast(1))
                                                            .map { (exp: String) -> String in
                                                                [e, sign, exp]
                                                                    .flatMap(id)
                                                                    .joined()
                                                            }
                                                    }
                                                }
                                        )
                                        .map { (eSignExp: String?) -> String in
                                            [minus, naturalPart, dotFractionalPart, eSignExp]
                                                .flatMap(id)
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

    static func stringLiteral() -> Parser<String> {
        return leadingWhitespace <|
            tag("STRING") <|
            Core.string("\"")
                .flatMap { _ -> Parser<String> in
                    Core.many(
                        Core.oneOf(
                            tag("UNESCAPED_CHARACTER") <|
                            Core.string(charset: Charset.stringUnescapedCharacters).map(String.init),
                            tag("ESCAPE_SEQUENCE") <|
                            Core.string("\\")
                                .flatMap { _ -> Parser<String> in
                                    Core.oneOf(
                                        Core.string("\"").map(String.init),
                                        Core.string("\\").map(String.init),
                                        Core.string("/").map(String.init),
                                        Core.string("b").map(const("\u{0008}")),
                                        Core.string("f").map(const("\u{000C}")),
                                        Core.string("n").map(const("\n")),
                                        Core.string("r").map(const("\r")),
                                        Core.string("t").map(const("\t")),
                                        Core.string("u")
                                            .flatMap { _ -> Parser<String> in
                                                Core.string(regex: "[0-9A-Fa-f]{4}")
                                                    .attemptMap { text, _ in
                                                        Int(text, radix: 16)
                                                            .flatMap(UnicodeScalar.init)
                                                            .map(Character.init)
                                                            .map(String.init)
                                                            .map(Either.right)
                                                        ??  .left(Mismatch(message: "Invalid unicode escape sequence \"\(text)\""))
                                                    }
                                            }
                                    )
                                }
                            )
                        )
                        .map { substrings in substrings.joined() }
                        .flatMap { text -> Parser<String> in
                            Core.string("\"")
                                .map(const(text))
                        }
                }
    }

    static func boolLiteral() -> Parser<Bool> {
        return leadingWhitespace <|
            tag("BOOL") <|
            Core.oneOf(
                Core.string(tag: "FALSE", "false")
                    .map(const(false)),
                Core.string(tag: "TRUE", "true")
                    .map(const(true))
            )
    }

    static func null() -> Parser<JSON> {
        return leadingWhitespace <|
            Core.string(tag: "NULL", "null")
                .map(const(JSON.null))
    }

    static func leadingWhitespace<T>(before parser: Parser<T>) -> Parser<T> {
        return Core.maybe(Core.string(tag: "WHITESPACE", charset: Charset.whitespace))
            .flatMap(tag: parser.tag.map { "_\($0)" }, const(parser))
    }

    static func tag<T>(_ tag: String) -> (Parser<T>) -> Parser<T> {
        return { parser in parser.map(tag: tag, id) }
    }
}

enum Charset {
    static let whitespace = CharacterSet(charactersIn: "\t\n\r ")
    static let nonZeroDigits = CharacterSet(charactersIn: "123456789")
    static let digits = CharacterSet(charactersIn: "0").union(nonZeroDigits)
    static let stringUnescapedCharacters =
        CharacterSet(charactersIn: UnicodeScalar(0) ... UnicodeScalar(0x1F))
        .union(CharacterSet(charactersIn: "\"\\"))
        .inverted
}
