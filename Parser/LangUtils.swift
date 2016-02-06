import Foundation

func typeName(some: Any) -> String {
    return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
}

func someName(some: Any) -> String {
    let type = typeName(some)
    let inst = "\(some)".componentsSeparatedByString("(").first! // The tail is mainly for `enum` with associated values.
    return (type != inst) ? "\(type).\(inst)" : inst
}

/// Cast the argument to the infered function return type.
func autocast<T>(some: Any) -> T? {
    return some as? T
}

func typeof<T>(some: T) -> T.Type {
    return T.self
}
