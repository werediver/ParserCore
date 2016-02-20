import Foundation

func typeName(some: Any) -> String {
    return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
}
