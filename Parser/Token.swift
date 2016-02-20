import Foundation

struct Token<Sym, Index: ForwardIndexType>: CustomStringConvertible {

    let sym: Sym

    let start: Index
    var   end: Index

    var range: Range<Index> {
        return Range(start: start, end: end)
    }

    init(sym: Sym, start: Index) {
        self.sym = sym
        self.start = start
        self.end   = start
    }

    init(sym: Sym, start: Index, end: Index) {
        self.sym = sym
        self.start = start
        self.end   = end
    }

    var description: String {
        return "{\(sym) \(start)..\(end)}"
    }

}
