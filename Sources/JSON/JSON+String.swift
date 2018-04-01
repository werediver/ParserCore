import ParserCore

extension JSONParser {

    static func stringLiteral() -> Parser<String> {
        return leadingWhitespace <|
            tag("STRING") <|
            Core.subseq("\"")
                .flatMap { _ -> Parser<String> in
                    Core.many(
                            Core.oneOf(
                                    tag("UNESCAPED_CHARACTER") <|
                                    Core.string(charset: Charset.stringUnescapedCharacters),
                                    tag("ESCAPE_SEQUENCE") <|
                                    Core.subseq("\\")
                                        .flatMap { _ -> Parser<String> in
                                            Core.oneOf(
                                                    Core.subseq("\"").map(String.init),
                                                    Core.subseq("\\").map(String.init),
                                                    Core.subseq("/").map(String.init),
                                                    Core.subseq("b").map(const("\u{0008}")),
                                                    Core.subseq("f").map(const("\u{000C}")),
                                                    Core.subseq("n").map(const("\n")),
                                                    Core.subseq("r").map(const("\r")),
                                                    Core.subseq("t").map(const("\t")),
                                                    Core.subseq("u")
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
                                ),
                            count: .atLeast(0)
                        )
                        .map { substrings in substrings.joined() }
                        .flatMap { text -> Parser<String> in
                            Core.subseq("\"")
                                .map(const(text))
                        }
                }
    }
}
