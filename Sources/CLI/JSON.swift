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
                leadingWhitespace <| Core.end()
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
        return leadingWhitespace <| Core.string(tag: "OBJECT_START", "{")
            .flatMap(tag: "OBJECT") { _ in
                Core.list(tag: "OBJECT_PROPERTIES", item: property(), separator: leadingWhitespace <| Core.string(","))
                    .flatMap { properties in
                        leadingWhitespace <| Core.string(tag: "OBJECT_END", "}")
                            .map { _ in .object(.init(uniqueKeysWithValues: properties)) }
                    }
            }
    }

    static func property() -> Parser<(String, JSON)> {
        return string()
            .flatMap(tag: "PROPERTY") { name in
                leadingWhitespace <| Core.string(":")
                    .flatMap { _ in
                        value()
                            .map { value in (name, value) }
                    }
            }
    }

    static func arrayValue() -> Parser<JSON> {
        return leadingWhitespace <| Core.string(tag: "ARRAY_START", "[")
            .flatMap { _ in
                Core.list(tag: "ARRAY_ITEMS", item: value(), separator: leadingWhitespace <| Core.string(","))
                    .flatMap { items in
                        leadingWhitespace <| Core.string(tag: "ARRAY_END", "]")
                            .map(const(.array(items)))
                    }
            }
    }

    static func numberValue() -> Parser<JSON> {
        return leadingWhitespace <| Core.string(tag: "NUMBER_RAW", regex: "-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?")
            .attemptMap(tag: "NUMBER") { firstGroup, _ in
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

    /// An overly simplified string parser
    static func string() -> Parser<String> {
        return leadingWhitespace <| Core.string(tag: "STRING_START", "\"")
            .flatMap { _ in
                Core.string(tag: "STRING_BODY", while: { $0 != "\"" })
                    .flatMap { string in
                        Core.string(tag: "STRING_END", "\"")
                            .map(const(String(string)))
                    }
            }
    }

    static func boolValue() -> Parser<JSON> {
        return leadingWhitespace <| Core.oneOf(
                tag: "BOOL",
                Core.string(tag: "FALSE", "false")
                    .map(const(JSON.bool(false))),
                Core.string(tag: "TRUE", "true")
                    .map(const(JSON.bool(true)))
            )
    }

    static func nullValue() -> Parser<JSON> {
        return leadingWhitespace <| Core.string(tag: "NULL", "null")
            .map(const(JSON.null))
    }

    static func leadingWhitespace<T>(and parser: Parser<T>) -> Parser<T> {
        return Core.skip(tag: "WHITESPACE", Core.string(charset: Charset.whitespace))
            .flatMap(const(parser))
    }
}

private enum Charset {
    static let whitespace = CharacterSet(charactersIn: "\t\n\r ")
    static let nonZeroDigits = CharacterSet(charactersIn: "123456789")
    static let digits = CharacterSet(charactersIn: "0").union(nonZeroDigits)
}
