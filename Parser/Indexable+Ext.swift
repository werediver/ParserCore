import Foundation

// This extension, in particular, adds the `count` method to any `CollectionType.SubSequence`.

extension Indexable {

    var fullRange: Range<Index> { return startIndex ..< endIndex }

    var count: Index.Distance {
        return startIndex.distanceTo(endIndex)
    }

}
