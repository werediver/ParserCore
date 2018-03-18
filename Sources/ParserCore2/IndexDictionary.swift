struct IndexDictionary<Key: Comparable, Value> {

    typealias Item = (key: Key, value: Value)

    private var items = [Item]()

    mutating func reserveCapacity(_ n: Int) {
        items.reserveCapacity(n)
    }

    subscript(key: Key) -> Value? {
        get { return get(key) }
        set { set(key, value: newValue) }
    }

    func get(_ key: Key) -> Value? {
        return items[safe: intendedIndex(of: key)]
            .flatMap { item in item.key == key ? item.value : nil }
    }

    mutating func set(_ key: Key, value: Value?) {
        let index = intendedIndex(of: key)

        if items[safe: index]?.key == key {
            if let value = value {
                items[index] = (key, value)
            } else {
                items.remove(at: index)
            }
        } else if let value = value {
            items.insert((key, value), at: index)
        }
    }

    private func intendedIndex(of key: Key) -> Int {
        var range = items.startIndex ..< items.endIndex

        while range.count > 0 {
            let middle = range.lowerBound + (range.upperBound - range.lowerBound) / 2
            let candidate = items[middle].key

            if candidate < key {
                range = middle + 1 ..< range.upperBound
            } else {
                range = range.lowerBound ..< middle
            }
        }

        return range.lowerBound
    }
}
