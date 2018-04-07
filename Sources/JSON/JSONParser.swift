import ParserCore

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
            Core.subseq(tag: "OBJECT_START", "{")
                .flatMap { _ in
                    Core.list(
                            item: property(),
                            separator: leadingWhitespace <| Core.subseq(",")
                        )
                        .flatMap { properties in
                            leadingWhitespace <|
                            Core.subseq(tag: "OBJECT_END", "}")
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
                    Core.subseq(":")
                        .flatMap { _ in
                            value()
                                .map { value in (name, value) }
                        }
                }
    }

    static func arrayLiteral() -> Parser<[JSON]> {
        return leadingWhitespace <|
            tag("ARRAY") <|
            Core.subseq(tag: "ARRAY_START", "[")
                .flatMap { _ in
                    Core.list(
                            item: value(),
                            separator: leadingWhitespace <| Core.subseq(",")
                        )
                        .flatMap { items in
                            leadingWhitespace <|
                            Core.subseq(tag: "ARRAY_END", "]")
                                .map(const(items))
                        }
                }
    }

    static func boolLiteral() -> Parser<Bool> {
        return leadingWhitespace <|
            tag("BOOL") <|
            Core.oneOf(
                Core.subseq(tag: "FALSE", "false")
                    .map(const(false)),
                Core.subseq(tag: "TRUE", "true")
                    .map(const(true))
            )
    }

    static func null() -> Parser<JSON> {
        return leadingWhitespace <|
            Core.subseq(tag: "NULL", "null")
                .map(const(JSON.null))
    }

    static func leadingWhitespace<T>(before parser: Parser<T>) -> Parser<T> {
        return Core.string(tag: "WHITESPACE", charset: Charset.whitespace, count: .atLeast(0))
            .flatMap(const(parser))
    }

    static func tag<T>(_ tag: String) -> (Parser<T>) -> Parser<T> {
        return { parser in parser.map(tag: tag, id) }
    }
}
