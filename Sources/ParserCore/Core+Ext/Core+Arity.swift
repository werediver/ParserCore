public extension SomeCore {

    static func maybe<Parser: SomeParser>(tag: String? = nil, _ parser: Parser) -> GenericParser<Self, Parser.Symbol?> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            .right(core.parse(parser).right)
        }
    }

    static func many<Parser: SomeParser>(
        tag: String? = nil,
        _ parser: Parser,
        count limit: CountLimit
    ) -> GenericParser<Self, [Parser.Symbol]> where
        Parser.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            var items = [Parser.Symbol]()
            while limit.extends(past: items.count),
                  let next = core.parse(parser).right {
                items.append(next)
            }

            if limit.contains(items.count) {
                return .right(items)
            }
            return .left(parser.tag.map { tag in Mismatch.expected("\(limit) \(tag)") } ?? Mismatch())
        }
    }
}
