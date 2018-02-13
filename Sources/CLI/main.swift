import ParserCore

let s = "1+2"
print(s)
let c = GenericParserCore(source: s)
let result = c.parse(LSumParser.start())
dump(result)
