import Foundation

struct RegEx {

    struct Result {

        let textCheckingResult: NSTextCheckingResult
        let ranges: [Range<String.Index>]
        let texts: [String]

        init(src: String, textCheckingResult: NSTextCheckingResult) {
            self.textCheckingResult = textCheckingResult
            ranges = (0 ..< textCheckingResult.numberOfRanges).flatMap { src.range(textCheckingResult.rangeAtIndex($0)) }
            texts = ranges.map { src[$0] }
        }

    }

    let regex: NSRegularExpression

    init(_ pattern: String, options: NSRegularExpressionOptions = []) {
        regex = try! NSRegularExpression(pattern: pattern, options: options)
    }

    func enumerateMatchesInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil, body: (Result?, NSMatchingFlags) -> Bool) {
        let nsRange = s.nsRange(range ?? s.fullRange)
        regex.enumerateMatchesInString(s, options: options, range: nsRange) { textCheckingResult, flags, stop in
            if textCheckingResult.flatMap({ body(Result(src: s, textCheckingResult: $0), flags) }) ?? false {
                stop.memory = true
            }
        }
    }

    func matchesInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil) -> [Result] {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return regex.matchesInString(s, options: options, range: nsRange).map { Result(src: s, textCheckingResult: $0) }
    }

    func numberOfMatchesInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil) -> Int {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return regex.numberOfMatchesInString(s, options: options, range: nsRange)
    }

    func firstMatchInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil) -> Result? {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return regex.firstMatchInString(s, options: options, range: nsRange).flatMap { Result(src: s, textCheckingResult: $0) }
    }

    func rangeOfFirstMatchInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil) -> Range<String.Index>? {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return s.range(regex.rangeOfFirstMatchInString(s, options: options, range: nsRange))
    }


    func stringByReplacingMatchesInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil, template: String) -> String {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return regex.stringByReplacingMatchesInString(s, options: options, range: nsRange, withTemplate: template)
    }

    func replaceMatchesInString(inout s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil, template: String) -> Int {
        var n = 0
        enumerateMatchesInString(s) { match, flags -> Bool in
            if let match = match,
               let range = match.ranges.first
            {
                s.replaceRange(range, with: template)
                n += 1
            }
            return false
        }
        return n
    }

}

extension RegEx: Equatable {}

func ==(a: RegEx, b: RegEx) -> Bool {
    return a.regex == b.regex
}

func ~=(pattern: RegEx, value: String) -> Bool {
    return pattern.firstMatchInString(value) != nil
}

extension RegEx: StringLiteralConvertible {

    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    typealias UnicodeScalarLiteralType = StringLiteralType

    init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }

    init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }

}

// MARK: - Range <-> NSRange

extension String {

    var fullRange: Range<String.Index> { return startIndex ..< endIndex }

    func range(nsRange : NSRange) -> Range<String.Index>? {
        let utf16start = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let utf16end   = utf16start.advancedBy(nsRange.length, limit: utf16.endIndex)

        if let start = String.Index(utf16start, within: self),
           let end   = String.Index(utf16end,   within: self)
        {
            return start ..< end
        } else {
            return nil
        }
    }

    func nsRange(range : Range<String.Index>) -> NSRange {
        let utf16start = String.UTF16View.Index(range.startIndex, within: utf16)
        let utf16end   = String.UTF16View.Index(range.endIndex,   within: utf16)
        return NSRange(location: utf16.startIndex.distanceTo(utf16start), length: utf16start.distanceTo(utf16end))
    }

}
