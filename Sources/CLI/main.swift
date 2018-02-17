import ParserCore

//let source = "1+2"
//print(source)
//let core = GenericParserCore(source: source)
//let result = core.parse(LSumParser.start())
//dump(result)

let source = " { \"\": 1, \"array\" : [ 123 , \"a\\nb\" , true , false , null , [ true ] , [ ] ] , \"nothing\" : null } "
print(source)
let core = GenericParserCore(source: source)
let result = core.parse(JSONParser.start())
dump(result)
if let ff = core.farthestFailure {
    let offset = source.distance(from: source.startIndex, to: ff.position)
    print("\nMismatches at offset \(offset):\n")
    ff.failures.forEach { f in
        print("\(f.trace)\n\(f.mismatch)\n")
    }
}
