struct Key {
    let offset: Int
    let tag: String
}

extension Key: Equatable {

    static func == (_ lhs: Key, _ rhs: Key) -> Bool {
        return lhs.offset == rhs.offset
            && lhs.tag == rhs.tag
    }
}

extension Key: Hashable {

    var hashValue: Int {
        return offset.hashValue ^ tag.hashValue
    }
}
