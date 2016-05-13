import Foundation

extension ForwardIndexType {

    @warn_unused_result
    public func advancedBy<N: SignedIntegerType>(n: N) -> Self {
        return advancedBy(Distance(n.toIntMax()))
    }

    @warn_unused_result
    public func advancedBy<N: SignedIntegerType>(n: N, limit: Self) -> Self {
        return advancedBy(Distance(n.toIntMax()), limit: limit)
    }

}
