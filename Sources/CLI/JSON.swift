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
                Core.end()
                    .map(const(value))
            }
    }

    static func value() -> Parser<JSON> {
        return Core.oneOf(
                tag: "VALUE",
                objectValue(),
                arrayValue(),
                //number(),
                stringValue(),
                boolValue(),
                nullValue()
            )
    }

    static func objectValue() -> Parser<JSON> {
        return Core.string(tag: "OBJECT_START", "{")
            .flatMap(tag: "OBJECT") { _ in
                Core.list(tag: "OBJECT_PROPERTIES", item: property(), separator: Core.string(","))
                    .flatMap { properties in
                        Core.string(tag: "OBJECT_END", "}")
                            .map { _ in .object(.init(uniqueKeysWithValues: properties)) }
                    }
            }
    }

    static func property() -> Parser<(String, JSON)> {
        return string()
            .flatMap(tag: "PROPERTY") { name in
                Core.string(":")
                    .flatMap { _ in
                        value()
                            .map { value in (name, value) }
                    }
            }
    }

    static func arrayValue() -> Parser<JSON> {
        return Core.string(tag: "ARRAY_START", "[")
            .flatMap { _ in
                Core.list(tag: "ARRAY_ITEMS", item: value(), separator: Core.string(","))
                    .flatMap { items in
                        Core.string(tag: "ARRAY_END", "]")
                            .map(const(.array(items)))
                    }
            }
    }

    static func numberValue() -> Parser<JSON> {
        fatalError()
    }

    static func stringValue() -> Parser<JSON> {
        return string()
            .map(JSON.string)
    }

    /// An overly simplified string parser
    static func string() -> Parser<String> {
        return Core.string(tag: "STRING_START", "\"")
            .flatMap { _ in
                Core.string(while: { $0 != "\"" })
                    .flatMap { string in
                        Core.string(tag: "STRING_END", "\"")
                            .map(const(String(string)))
                    }
            }
    }

    static func boolValue() -> Parser<JSON> {
        return Core.oneOf(
                tag: "BOOL",
                Core.string(tag: "FALSE", "false")
                    .map(const(JSON.bool(false))),
                Core.string(tag: "TRUE", "true")
                    .map(const(JSON.bool(true)))
            )
    }

    static func nullValue() -> Parser<JSON> {
        return Core.string(tag: "NULL", "null")
            .map(const(JSON.null))
    }
}

private let whitespace = CharacterSet(charactersIn: "\t\n\r ")
