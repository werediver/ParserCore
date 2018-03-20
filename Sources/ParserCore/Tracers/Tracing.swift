public protocol Tracing: class {

    associatedtype Index: Comparable

    func trace<Symbol>(position: Index, tag: String?, call body: () -> Either<Mismatch, GenericMatch<Symbol, Index>>) -> Either<Mismatch, GenericMatch<Symbol, Index>>

    func report() -> String?
}

public extension Tracing {

    func combine<Other: Tracing>(with other: Other) -> CompositeTracer<Self, Other> {
        return CompositeTracer(self, other)
    }
}

public final class CompositeTracer<Tracer1: Tracing, Tracer2: Tracing>: Tracing where
    Tracer1.Index == Tracer2.Index
{

    public typealias Index = Tracer1.Index

    private let tracer1: Tracer1
    private let tracer2: Tracer2

    init(_ tracer1: Tracer1, _ tracer2: Tracer2) {
        self.tracer1 = tracer1
        self.tracer2 = tracer2
    }

    public func trace<Symbol>(position: Index, tag: String?, call body: () -> Either<Mismatch, GenericMatch<Symbol, Index>>) -> Either<Mismatch, GenericMatch<Symbol, Index>> {
        return tracer1.trace(position: position, tag: tag) { [tracer2] in
            tracer2.trace(position: position, tag: tag, call: body)
        }
    }

    public func report() -> String? {
        return [tracer1.report(), tracer2.report()]
            .flatMap(id)
            .joined(separator: "\n\n")
    }
}

public final class EmptyTracer<Index: Comparable>: Tracing {

    public func trace<Symbol>(position: Index, tag: String?, call body: () -> Either<Mismatch, GenericMatch<Symbol, Index>>) -> Either<Mismatch, GenericMatch<Symbol, Index>> {
        return body()
    }

    public func report() -> String? { return nil }
}
