import Foundation

protocol TokenType: CustomDebugStringConvertible {

    associatedtype Symbol
    associatedtype Index: ForwardIndexType

    var sym: Symbol { get }
    var range: Range<Index> { get }

    init(sym: Symbol, range: Range<Index>)

}

extension TokenType {

    var debugDescription: String {
        return "[\(sym) \(range)]"
    }

}

// MARK: - Common token implementations

struct GenericToken<Symbol, Index: ForwardIndexType>: TokenType {

    var sym: Symbol
    var range: Range<Index>

}

struct TextToken<Symbol>: TokenType {

    typealias Index = String.Index

    var sym: Symbol
    var range: Range<Index>

}

struct CommonToken<Symbol>: TokenType {

    typealias Index = Int

    var sym: Symbol
    var range: Range<Index>

}
