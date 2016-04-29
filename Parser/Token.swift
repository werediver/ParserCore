import Foundation

protocol TokenType: CustomDebugStringConvertible {

    associatedtype SymbolType
    associatedtype Index: ForwardIndexType

    var sym: SymbolType { get }
    var range: Range<Index> { get }

    init(sym: SymbolType, range: Range<Index>)

}

extension TokenType {

    var debugDescription: String {
        return "[\(sym) \(range)]"
    }

}

// MARK: - Common token implementations

struct GenericToken<SymbolType, Index: ForwardIndexType>: TokenType {

    var sym: SymbolType
    var range: Range<Index>

}

struct TextToken<SymbolType>: TokenType {

    typealias Index = String.Index

    var sym: SymbolType
    var range: Range<Index>

}

struct CommonToken<SymbolType>: TokenType {

    typealias Index = Int

    var sym: SymbolType
    var range: Range<Index>

}
