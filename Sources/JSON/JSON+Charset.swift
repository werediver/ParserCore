import struct Foundation.CharacterSet

enum Charset {

    static let whitespace = CharacterSet(charactersIn: "\t\n\r ")
    static let digits = CharacterSet.decimalDigits
    static let nonZeroDigits = CharacterSet
        .decimalDigits
        .subtracting(CharacterSet(charactersIn: "0"))
    static let stringUnescapedCharacters =
        CharacterSet(charactersIn: UnicodeScalar(0) ... UnicodeScalar(0x1F))
        .union(CharacterSet(charactersIn: "\"\\"))
        .inverted
}
