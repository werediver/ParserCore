import Foundation

struct CaretPosition: CustomStringConvertible {

    var line: Int
    var column: Int

    var description: String { return "\(line):\(column)" }

}

extension Lexer
    where TargetSymbol.Source == String.CharacterView
{

    convenience init(src: String) {
        self.init(src: src.characters)
    }

    func caretPosition(srcIndex: TargetSymbol.Source.Index) -> CaretPosition {
        let eols = (src.startIndex ..< srcIndex).flatMap { (src[$0] == "\n") ? $0 : nil }
        let (line, lineStartIndex) = eols.fullRange.flatMap({ (eols[$0] < srcIndex) ? ($0, eols[$0]) : nil }).last ?? (0, src.startIndex)
        let column = lineStartIndex.distanceTo(srcIndex)
        return CaretPosition(line: line, column: column)
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

    func match(src: Source.SubSequence) -> Source.Index.Distance {
        return rawValue.rangeOfFirstMatchInString(String(src), options: .Anchored)?.count ?? 0
    }

}
