import Foundation

extension String {

    func mul(n: Int) -> String {
        return Repeat(count: n, repeatedValue: self).joinWithSeparator("")
    }

}
