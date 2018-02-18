import Foundation
import ParserCore

enum JSON {

    typealias Object = [String: JSON]

    case object(Object)
    indirect case array([JSON])
    case number(Double)
    case string(String)
    case bool(Bool)
    case null
}

enum JSONParser<Core: ParserCoreProtocol> where
    Core.Source == String
{
    typealias Parser<Symbol> = GenericParser<Core, Symbol>

    static func start() -> Parser<JSON> {
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
                objectValue(),
                arrayValue(),
                numberValue(),
                stringValue(),
                boolValue(),
                nullValue()
            )
    }

    static func objectValue() -> Parser<JSON> {
        return leadingWhitespace <|
            Core.string(tag: "OBJECT_START", "{")
                .flatMap(tag: "OBJECT_VALUE") { _ in
                    Core.list(
                            item: property(),
                            separator: leadingWhitespace <| Core.string(",")
                        )
                        .flatMap { properties in
                            leadingWhitespace <|
                            Core.string(tag: "OBJECT_END", "}")
                                .map { _ in .object(.init(uniqueKeysWithValues: properties)) }
                        }
                }
    }

    static func property() -> Parser<(String, JSON)> {
        return string()
            .flatMap(tag: "PROPERTY") { name in
                leadingWhitespace <|
                Core.string(":")
                    .flatMap { _ in
                        value()
                            .map { value in (name, value) }
                    }
            }
    }

    static func arrayValue() -> Parser<JSON> {
        return leadingWhitespace <|
            Core.string(tag: "ARRAY_START", "[")
                .flatMap(tag: "ARRAY_VALUE") { _ in
                    Core.list(
                            item: value(),
                            separator: leadingWhitespace <| Core.string(",")
                        )
                        .flatMap { items in
                            leadingWhitespace <|
                            Core.string(tag: "ARRAY_END", "]")
                                .map(const(.array(items)))
                        }
                }
    }

    static func numberValue() -> Parser<JSON> {
        return leadingWhitespace <|
            Core.string(regex: "-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?")
                .attemptMap(tag: "NUMBER_VALUE") { firstGroup, _ in
                    Double(firstGroup)
                        .map(JSON.number)
                        .map(Either.right)
                    ??  .left(Mismatch())
                }
    }

    static func stringValue() -> Parser<JSON> {
        return string()
            .map(JSON.string)
    }

    static func string() -> Parser<String> {
        return leadingWhitespace <|
            Core.string("\"")
                .flatMap(tag: "STRING") { _ -> Parser<String> in
                    Core.many(
                        Core.oneOf(
                            Core.string(charset: Charset.stringUnescapedCharacters)
                                .attemptMap { text in
                                    text.count > 0 ? .right(String(text)) : .left(Mismatch())
                                },
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
                        .map { $0.joined() }
                        .flatMap { text -> Parser<String> in
                            Core.string("\"")
                                .map(const(text))
                        }
                }
    }

    static func boolValue() -> Parser<JSON> {
        return leadingWhitespace <|
            Core.oneOf(
                tag: "BOOL_VALUE",
                Core.string(tag: "FALSE", "false")
                    .map(const(JSON.bool(false))),
                Core.string(tag: "TRUE", "true")
                    .map(const(JSON.bool(true)))
            )
    }

    static func nullValue() -> Parser<JSON> {
        return leadingWhitespace <|
            Core.string("null")
                .map(tag: "NULL_VALUE", const(JSON.null))
    }

    static func leadingWhitespace<T>(before parser: Parser<T>) -> Parser<T> {
        return Core.skip(Core.string(tag: "WHITESPACE", charset: Charset.whitespace))
            .flatMap(tag: parser.tag.map { "_\($0)" }, const(parser))
    }
}

private enum Charset {
    static let whitespace = CharacterSet(charactersIn: "\t\n\r ")
    static let nonZeroDigits = CharacterSet(charactersIn: "123456789")
    static let digits = CharacterSet(charactersIn: "0").union(nonZeroDigits)
    static let stringUnescapedCharacters = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: "\"\\")).inverted
}
