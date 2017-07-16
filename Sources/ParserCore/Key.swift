struct Key {
    let offset: Int
    let tag: String
}

extension Key: Hashable {

    var hashValue: Int {
        return offset.hashValue ^ tag.hashValue
    }

    static func == (_ a: Key, _ b: Key) -> Bool {
        return a.offset == b.offset
            && a.tag == b.tag
    }
}
