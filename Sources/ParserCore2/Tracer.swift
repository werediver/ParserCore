protocol Tracing {

    associatedtype Index: Comparable

    mutating func trace<T>(position: Index, tag: String?, call: () -> Either<Mismatch, T>) -> Either<Mismatch, T>
}

struct Tracer<Index: Comparable, IndexDistance>: Tracing {

    typealias Offset = (Index) -> IndexDistance

    private typealias Call = (position: Index, tag: String?, depth: Int)

    private var stack = [Call]()
    private var farthestMismatch: (position: Index, list: [(stack: [Call], mismatch: Mismatch)])?
    private let offset: Offset

    init(offset: @escaping Offset) {
        self.offset = offset
    }

    mutating func trace<T>(position: Index, tag: String?, call: () -> Either<Mismatch, T>) -> Either<Mismatch, T> {
        enter(position: position, tag: tag)

        let match = call()

        if let mismatch = match.left {
            register(mismatch)
        }

        leave()

        return match
    }

    private mutating func enter(position: Index, tag: String?) {
        if let call = stack.last, call.position == position, call.tag == tag {
            stack[stack.index(before: stack.endIndex)] = (call.position, call.tag, call.depth + 1)
        } else {
            stack.append((position, tag, 1))
        }
    }

    private mutating func leave() {
        let call = stack.last!
        if call.depth > 1 {
            stack[stack.index(before: stack.endIndex)] = (call.position, call.tag, call.depth - 1)
        } else {
            stack.removeLast()
        }
    }

    private mutating func register(_ mismatch: Mismatch) {
        let call = stack.last!
        if farthestMismatch.map({ $0.position < call.position }) != false {
            farthestMismatch = (call.position, [(stack, mismatch)])
        } else if let farthestMismatch = farthestMismatch, farthestMismatch.position == call.position {
            self.farthestMismatch = (call.position, farthestMismatch.list + [(stack, mismatch)])
        }
    }
}

extension Tracer: CustomStringConvertible {

    var description: String {
        return stack
            .reversed()
            .map { record in
                let base = "\(offset(record.position)):\(String(optional: record.tag))"
                let tail = record.depth > 1 ? "×\(record.depth)" : ""
                return base + tail
            }
            .joined(separator: " ◂ ")
    }
}
