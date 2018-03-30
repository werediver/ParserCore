import Foundation

public struct RegEx {

    public struct Result {

        public let ranges: [Range<String.Index>]
        public let groups: [String]
        public var firstGroup: String! { return groups.first }

        public init(_ result: NSTextCheckingResult, in src: String) {
            self.ranges = (0 ..< result.numberOfRanges)
                .compactMap { index in Range(result.range(at: index), in: src) }
            self.groups = ranges.map { range in String(src[range]) }
        }
    }

    public let regex: NSRegularExpression

    public init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
        regex = try NSRegularExpression(pattern: pattern, options: options)
    }

    public func enumerateMatches(in text: String, options: NSRegularExpression.MatchingOptions = [], range: Range<String.Index>? = nil, body: (Result?, NSRegularExpression.MatchingFlags) -> Bool) {
        let nsRange = NSRange(range ?? text.fullRange, in: text)
        regex.enumerateMatches(in: text, options: options, range: nsRange) { textCheckingResult, flags, stop in
            if textCheckingResult.flatMap({ body(Result($0, in: text), flags) }) ?? false {
                stop.pointee = true
            }
        }
    }

    public func matches(in text: String, options: NSRegularExpression.MatchingOptions = [], range: Range<String.Index>? = nil) -> [Result] {
        let nsRange = NSRange(range ?? text.fullRange, in: text)
        return regex.matches(in: text, options: options, range: nsRange).map { Result($0, in: text) }
    }

    public func numberOfMatches(in text: String, options: NSRegularExpression.MatchingOptions = [], range: Range<String.Index>? = nil) -> Int {
        let nsRange = NSRange(range ?? text.fullRange, in: text)
        return regex.numberOfMatches(in: text, options: options, range: nsRange)
    }

    public func firstMatch(in text: String, options: NSRegularExpression.MatchingOptions = [], range: Range<String.Index>? = nil) -> Result? {
        let nsRange = NSRange(range ?? text.fullRange, in: text)
        return regex.firstMatch(in: text, options: options, range: nsRange).flatMap { Result($0, in: text) }
    }

    public func rangeOfFirstMatch(in text: String, options: NSRegularExpression.MatchingOptions = [], range: Range<String.Index>? = nil) -> Range<String.Index>? {
        let nsRange = NSRange(range ?? text.fullRange, in: text)
        return Range(regex.rangeOfFirstMatch(in: text, options: options, range: nsRange), in: text)
    }

    public func stringByReplacingMatches(in text: String, options: NSRegularExpression.MatchingOptions = [], range: Range<String.Index>? = nil, template: String) -> String {
        let nsRange = NSRange(range ?? text.fullRange, in: text)
        return regex.stringByReplacingMatches(in: text, options: options, range: nsRange, withTemplate: template)
    }

    public func replaceMatches(in text: inout String, options: NSRegularExpression.MatchingOptions = [], range: Range<String.Index>? = nil, template: String) -> Int {
        var n = 0
        enumerateMatches(in: text) { match, flags -> Bool in
            if let match = match,
               let range = match.ranges.first
            {
                text.replaceSubrange(range, with: template)
                n += 1
            }
            return false
        }
        return n
    }
}

extension RegEx: Equatable {

    public static func ==(lhs: RegEx, rhs: RegEx) -> Bool {
        return lhs.regex == rhs.regex
    }
}

extension RegEx: Hashable {

    public var hashValue: Int { return regex.hashValue }
}

public func ~=(pattern: RegEx, value: String) -> Bool {
    return pattern.firstMatch(in: value) != nil
}

extension RegEx: ExpressibleByStringLiteral {

    public init(stringLiteral value: StringLiteralType) {
        try! self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        try! self.init(value)
    }

    public init(unicodeScalarLiteral value: StringLiteralType) {
        try! self.init(value)
    }
}

private extension String {

    var fullRange: Range<String.Index> { return startIndex ..< endIndex }
}
