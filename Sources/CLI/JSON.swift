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
                //object(),
                array(),
                //number(),
                //string(),
                bool(),
                null()
            )
    }

    static func object() -> Parser<JSON> {
        fatalError()
    }

    static func array() -> Parser<JSON> {
        return Core.string(tag: "ARRAY_START", "[")
            .flatMap { _ in
                Core.list(tag: "ARRAY_ITEMS", item: value(), separator: Core.string(","))
                    .flatMap { items in
                        Core.string(tag: "ARRAY_END", "]")
                            .map(const(.array(items)))
                    }
            }
    }

    static func number() -> Parser<JSON> {
        fatalError()
    }

    static func string() -> Parser<JSON> {
        fatalError()
    }

    static func bool() -> Parser<JSON> {
        return Core.oneOf(
                tag: "BOOL",
                Core.string(tag: "FALSE", "false")
                    .map(const(JSON.bool(false))),
                Core.string(tag: "TRUE", "true")
                    .map(const(JSON.bool(true)))
            )
    }

    static func null() -> Parser<JSON> {
        return Core.string(tag: "NULL", "null")
            .map(const(JSON.null))
    }
}

private let whitespace = CharacterSet(charactersIn: "\t\n\r ")
