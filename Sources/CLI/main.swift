import ParserCore

//let source = "1+2"
//print(source)
//let core = GenericParserCore(source: source)
//let result = core.parse(LSumParser.start())
//dump(result)

let source = "[true,false,null,[true],[]]"
print(source)
let core = GenericParserCore(source: source)
let result = core.parse(JSONParser.start())
dump(result)
