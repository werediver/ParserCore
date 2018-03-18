precedencegroup ForwardPipePrecedence {
    higherThan: AssignmentPrecedence
}

precedencegroup BackwardPipePrecedence {
    higherThan: AssignmentPrecedence
    associativity: right
}

infix operator |>: ForwardPipePrecedence
infix operator <|: BackwardPipePrecedence

public func |> <T, U>(lhs: T, rhs: (T) -> U) -> U {
    return rhs(lhs)
}

public func <| <T, U>(lhs: (T) -> U, rhs: T) -> U {
    return lhs(rhs)
}
