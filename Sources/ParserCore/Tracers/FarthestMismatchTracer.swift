public final class FarthestMismatchTracer<Index: Comparable, IndexDistance>: Tracing {

    typealias Offset = (Index) -> IndexDistance

    private typealias Call = (position: Index, tag: String?, depth: Int)

    private var stack = [Call]()
    private var farthestMismatch: (position: Index, list: [(stack: [Call], mismatch: Mismatch)])?
    private let offset: Offset

    init(offset: @escaping Offset) {
        self.offset = offset
    }

    public func trace<Symbol>(position: Index, tag: String?, call body: () -> Either<Mismatch, GenericMatch<Symbol, Index>>) -> Either<Mismatch, GenericMatch<Symbol, Index>> {
        enter(position: position, tag: tag)

        let match = body()

        if let mismatch = match.left {
            register(mismatch)
        }

        leave()

        return match
    }

    private func enter(position: Index, tag: String?) {
        if let call = stack.last, call.position == position, call.tag == tag {
            stack[stack.index(before: stack.endIndex)] = (call.position, call.tag, call.depth + 1)
        } else {
            stack.append((position, tag, 1))
        }
    }

    private func leave() {
        let call = stack.last!
        if call.depth > 1 {
            stack[stack.index(before: stack.endIndex)] = (call.position, call.tag, call.depth - 1)
        } else {
            stack.removeLast()
        }
    }

    private func register(_ mismatch: Mismatch) {
        let call = stack.last!
        if farthestMismatch.map({ $0.position < call.position }) ?? true {
            farthestMismatch = (call.position, [(stack, mismatch)])
        } else if let farthestMismatch = farthestMismatch,
            farthestMismatch.position == call.position,
            farthestMismatch.list.last?.mismatch != mismatch
        {
            self.farthestMismatch = (call.position, farthestMismatch.list + [(stack, mismatch)])
        }
    }

    public func report() -> String? {
        return farthestMismatch.map { farthestMismatch in
            let mismatches = farthestMismatch.list
                .map { "\(description(of: $0.stack))\n\($0.mismatch)" }
                .joined(separator: "\n\n")
            return "Mismatches at position \(farthestMismatch.position):\n\n\(mismatches)"
        }
    }

    private func description(of stack: [Call]) -> String {
        return stack
            .filter { record in record.tag != nil }
            .reversed()
            .map { record in
                let base = "\(offset(record.position)):\(describe(record.tag))"
                let tail = record.depth > 1 ? "×\(record.depth)" : ""
                return base + tail
            }
            .joined(separator: " ◂ ")
    }
}

extension FarthestMismatchTracer: CustomStringConvertible {

    public var description: String { return description(of: stack) }
}
