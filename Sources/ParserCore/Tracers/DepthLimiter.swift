public final class DepthLimiter<Index: Comparable & Hashable>: Tracing {

    typealias TailLength = (Index) -> Int

    private let tailLength: TailLength
    private var depthMapMap = Dictionary<Index, [String: Int]>()

    init(sourceLength: Int, tailLength: @escaping TailLength) {
        self.tailLength = tailLength
        depthMapMap.reserveCapacity(sourceLength)
    }

    public func trace<Symbol>(position: Index, tag: String?, call body: () -> Either<Mismatch, GenericMatch<Symbol, Index>>) -> Either<Mismatch, GenericMatch<Symbol, Index>> {
        guard let tag = tag
        else { return body() }

        var depthMap = depthMapMap[position] ?? [:]
        let depth = depthMap[tag] ?? 0
        if depth <= tailLength(position) {
            depthMap[tag] = depth + 1
            depthMapMap[position] = depthMap
            let match = body()
            depthMap[tag] = depth
            depthMapMap[position] = depthMap
            return match
        } else {
            return .left(Mismatch())
        }
    }

    public func report() -> String? {
        return nil
    }
}
