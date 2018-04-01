import ParserCore

extension JSONParser {

    static func stringLiteral() -> Parser<String> {
        return leadingWhitespace <|
            tag("STRING") <|
            Core.string("\"")
                .flatMap { _ -> Parser<String> in
                    Core.many(
                            Core.oneOf(
                                    tag("UNESCAPED_CHARACTER") <|
                                    Core.string(charset: Charset.stringUnescapedCharacters),
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
}
