import Foundation

protocol Token: CustomStringConvertible {

    typealias Symbol
    typealias Index: ForwardIndexType

    var sym: Symbol { get }

    var start: Index { get }
    var end: Index { get set }

    var range: Range<Index> { get } // start ..< end

    init(sym: Symbol, start: Index, end: Index)
    init(sym: Symbol, start: Index) // convenience, end = start

}

extension Token {

    var range: Range<Index> {
        return Range(start: start, end: end)
    }

    init(sym: Symbol, start: Index) {
        self.init(sym: sym, start: start, end: start)
    }

    // MARK: - CustomStringConvertible

    var description: String {
        return "<\(sym) \(start)..\(end)>"
    }

}

// MARK: - Common token implementations

struct GeneralToken<Symbol, Index: ForwardIndexType>: Token {

    let sym: Symbol

    let start: Index
    var   end: Index

}

struct TextToken<Symbol>: Token {

    typealias Index = String.Index

    let sym: Symbol

    let start: Index
    var   end: Index

}

struct CommonToken<Symbol>: Token {

    typealias Index = Int

    let sym: Symbol

    let start: Index
    var   end: Index

}
