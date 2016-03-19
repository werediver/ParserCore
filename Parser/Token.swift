import Foundation

protocol TokenType: CustomDebugStringConvertible {

    typealias Symbol
    typealias Index: ForwardIndexType

    var sym: Symbol { get }

    var start: Index { get }
    var end: Index { get set }

    var range: Range<Index> { get } // start ..< end

    init(sym: Symbol, start: Index, end: Index)
    init(sym: Symbol, start: Index) // convenience, end = start

}

extension TokenType {

    var range: Range<Index> {
        return Range(start: start, end: end)
    }

    init(sym: Symbol, start: Index) {
        self.init(sym: sym, start: start, end: start)
    }

    // MARK: - CustomDebugStringConvertible

    var debugDescription: String {
        return "<\(sym) \(start)..\(end)>"
    }

}

// MARK: - Common token implementations

struct GenericToken<Symbol, Index: ForwardIndexType>: TokenType {

    let sym: Symbol

    let start: Index
    var   end: Index

}

struct TextToken<Symbol>: TokenType {

    typealias Index = String.Index

    let sym: Symbol

    let start: Index
    var   end: Index

}

struct CommonToken<Symbol>: TokenType {

    typealias Index = Int

    let sym: Symbol

    let start: Index
    var   end: Index

}
