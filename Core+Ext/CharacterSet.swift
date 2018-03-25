import struct Foundation.CharacterSet

public extension SomeCore where
    Source == String
{
    static func string(
        tag: String? = nil,
        charset: CharacterSet,
        count limit: CountLimit = .atLeast(1)
    ) -> GenericParser<Self, String> {
        return string(tag: tag, while: charset.contains, count: limit).map(String.init)
    }
}

private extension CharacterSet {

    func contains(_ c: Character) -> Bool {
        for scalar in String(c).unicodeScalars {
            if !self.contains(scalar) {
                return false
            }
        }
        return true
    }
}
