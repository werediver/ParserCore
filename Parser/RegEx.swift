import Foundation

struct RegEx {

    let regex: NSRegularExpression

    init(_ pattern: String, options: NSRegularExpressionOptions = []) {
        regex = try! NSRegularExpression(pattern: pattern, options: options)
    }

    func enumerateMatchesInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil, body: (NSTextCheckingResult?, NSMatchingFlags) -> Bool) {
        let nsRange = s.nsRange(range ?? s.fullRange)
        regex.enumerateMatchesInString(s, options: options, range: nsRange) { result, flags, stop in
            if body(result, flags) {
                stop.memory = true
            }
        }
    }

    func matchesInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil) -> [NSTextCheckingResult] {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return regex.matchesInString(s, options: options, range: nsRange)
    }

    func numberOfMatchesInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil) -> Int {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return regex.numberOfMatchesInString(s, options: options, range: nsRange)
    }

    func firstMatchInString(s: String, options: NSMatchingOptions = [], range: Range<String.Index>? = nil) -> NSTextCheckingResult? {
        let nsRange = s.nsRange(range ?? s.fullRange)
        return regex.firstMatchInString(s, options: options, range: nsRange)
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
               let range = s.range(match.range)
            {
                s.replaceRange(range, with: template)
                n = n + 1
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

func ~=(pattern: RegEx, value: String) -> Bool {
    return pattern.firstMatchInString(value) != nil
}

// MARK: - Range <-> NSRange

extension String {

    var fullRange: Range<String.Index> { return startIndex ..< endIndex }

    func range(nsRange : NSRange) -> Range<String.Index>? {
        let utf16from = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let utf16to   = utf16from.advancedBy(nsRange.length, limit: utf16.endIndex)

        if let from = String.Index(utf16from, within: self),
           let to   = String.Index(utf16to,   within: self)
        {
            return from ..< to
        } else {
            return nil
        }
    }

    func nsRange(range : Range<String.Index>) -> NSRange {
        let utf16from = String.UTF16View.Index(range.startIndex, within: utf16)
        let utf16to   = String.UTF16View.Index(range.endIndex,   within: utf16)
        return NSRange(location: utf16.startIndex.distanceTo(utf16from), length: utf16from.distanceTo(utf16to))
    }

}
