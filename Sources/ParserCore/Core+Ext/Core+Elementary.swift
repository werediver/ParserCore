public extension SomeCore {

    static func empty(tag: String? = nil) -> GenericParser<Self, ()> {
        return GenericParser(tag: tag, const(.right(Void())))
    }

    static func end() -> GenericParser<Self, ()> {
        return GenericParser<Self, ()> { _, core in
            core.accept { tail -> Match<()>? in
                    if tail.startIndex == tail.endIndex {
                        return Match(symbol: (), range: tail.startIndex ..< tail.endIndex)
                    }
                    return nil
                }
                .map(Either.right)
            ??  .left(.expected("end of input"))
        }
    }
}
