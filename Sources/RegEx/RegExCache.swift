import Foundation

final class RegExCache {

    static var shared = RegExCache()

    func make(_ pattern: String, options: NSRegularExpression.Options = []) throws -> RegEx {
        let key = Key(pattern: pattern, options: options)
        if let cached = cache[key] {
            return cached
        } else {
            let regex = try RegEx(pattern, options: options)
            cache[key] = regex
            return regex
        }
    }

    private var cache = [Key: RegEx]()

    private struct Key: Hashable {

        let pattern: String
        let options: NSRegularExpression.Options

        var hashValue: Int { return pattern.hashValue ^ options.rawValue.hashValue }

        static func ==(lhs: Key, rhs: Key) -> Bool {
            return lhs.pattern == rhs.pattern
                && lhs.options == rhs.options
        }
    }
}

extension RegEx {

    public static func make(_ pattern: String, options: NSRegularExpression.Options = []) throws -> RegEx {
        return try RegExCache.shared.make(pattern, options: options)
    }
}
