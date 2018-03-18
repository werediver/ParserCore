public struct GenericMatch<Symbol, Index: Comparable> {

    public let symbol: Symbol
    public let range: Range<Index>

    public init(symbol: Symbol, range: Range<Index>) {
        self.symbol = symbol
        self.range = range
    }
}
