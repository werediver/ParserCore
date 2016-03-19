import Foundation

// This extension, in particular, adds the `count` method to any `CollectionType.SubSequence`.

extension Indexable {

    var count: Index.Distance {
        return startIndex.distanceTo(endIndex)
    }

}
