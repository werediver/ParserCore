import Foundation

extension String {

    func mul(n: Int) -> String {
        var s = ""
        for _ in 0 ..< n {
            s += self
        }
        return s
    }

}
