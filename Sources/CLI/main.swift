import ParserCore

let s = "1+2"
print(s)
let c = GenericParserCore(source: s.characters)
let r = c.parse(LSumParser.start())
dump(r.map { $0.symbol })
