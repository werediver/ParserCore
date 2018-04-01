public extension SomeCore {

    // TODO: Optionally allow trailing comma.
    static func list<Item: SomeParser, Separator: SomeParser>(tag: String? = nil, item: Item, separator: Separator) -> GenericParser<Self, [Item.Symbol]> where
        Item.Core == Self,
        Separator.Core == Self
    {
        return GenericParser(tag: tag) { _, core in
            core.parse(item)
                .map { first in
                    var items = [first]
                    let followingItem = separator.flatMap(const(item))
                    while let next = core.parse(followingItem).right {
                        items.append(next)
                    }
                    return .right(items)
                }
                .iif(right: id, left: const(.right([])))
        }
    }
}
