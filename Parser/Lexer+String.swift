import Foundation

struct CaretPosition: CustomStringConvertible {

    var line: Int
    var column: Int

    var description: String { return "\(line):\(column)" }

}

extension LexAnalyser
    where TargetSymbol.Source == String.CharacterView
{

    convenience init(src: String) {
        self.init(src: src.characters)
    }

    func caretPosition(offset: String.Index) -> CaretPosition {
        let eols = (src.startIndex ..< offset).flatMap { (src[$0] == "\n") ? $0 : nil }
        let line = eols.count
        let lineStartIndex = eols.last?.advancedBy(1) ?? src.startIndex
        let column = lineStartIndex.distanceTo(offset)
        return CaretPosition(line: line + 1, column: column + 1)
    }

    func tokenDescription(token: Token) -> String {
        let pos = caretPosition(token.range.startIndex)
        return "<\(token.sym) \(pos) \"\(String(src[token.range]))\">"
    }

}

extension TerminalSymbolType
    where Source == String.CharacterView,
          Self: RawRepresentable, Self.RawValue == RegEx
{

    func match(tail: Source.SubSequence) -> Source.Index.Distance {
        return rawValue.rangeOfFirstMatchInString(String(tail), options: .Anchored)?.count ?? 0
    }

}
