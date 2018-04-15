import ParserCore

extension JSONParser {

    static func stringLiteral() -> Parser<String> {
        return leadingWhitespace <|
            tag("STRING") <|
            Core.subseq(tag: "STRING_START", "\"")
                .flatMap { _ -> Parser<String> in
                    Core.many(
                            Core.oneOf(
                                    Core.string(
                                            tag: "UNESCAPED_CHARACTER",
                                            charset: Charset.stringUnescapedCharacters
                                        ),
                                    Core.subseq(tag: "ESCAPE_SEQUENCE", "\\")
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
                                                            Core.string(charset: Charset.hexDigits, count: .exactly(4))
                                                                .attemptMap { text in
                                                                    Int(text, radix: 16)
                                                                        .flatMap(UnicodeScalar.init)
                                                                        .map(Character.init)
                                                                        .map(String.init)
                                                                        .map(Either.right)
                                                                    ??  .left(.cannotConvert(String(reflecting: text), to: "Unicode scalar"))
                                                                }
                                                        }
                                                )
                                        }
                                ),
                            count: .atLeast(0)
                        )
                        .map { substrings in substrings.joined() }
                        .flatMap { text -> Parser<String> in
                            Core.subseq(tag: "STRING_END", "\"")
                                .map(const(text))
                        }
                }
    }
}
