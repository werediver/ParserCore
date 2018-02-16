import Foundation

public struct RegEx {

    public struct Result {

        public let ranges: [Range<String.Index>]
        public let matches: [String]

        public init(_ result: NSTextCheckingResult, in src: String) {
            self.ranges = (0 ..< result.numberOfRanges).flatMap { Range(result.range(at: $0), in: src) }
            self.matches = ranges.map { String(src[$0]) }
        }
    }

    public let regex: NSRegularExpression

    public init(_ pattern: String, options: NSRegularExpression.Options = []) {
        regex = try! NSRegularExpression(pattern: pattern, options: options)
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

public func ~=(pattern: RegEx, value: String) -> Bool {
    return pattern.firstMatch(in: value) != nil
}

extension RegEx: ExpressibleByStringLiteral {

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
}

private extension String {

    var fullRange: Range<String.Index> { return startIndex ..< endIndex }
}
