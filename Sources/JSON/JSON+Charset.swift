import struct Foundation.CharacterSet

enum Charset {

    static let whitespace = CharacterSet(charactersIn: "\t\n\r ")
    static let digits = CharacterSet(charactersIn: "0123456789")
    static let nonZeroDigits = CharacterSet(charactersIn: "123456789")
    static let hexDigits = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
    static let stringUnescapedCharacters =
        CharacterSet(charactersIn: UnicodeScalar(0) ... UnicodeScalar(0x1F))
        .union(CharacterSet(charactersIn: "\"\\"))
        .inverted
}
