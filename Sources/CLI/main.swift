import Foundation
import ParserCore2
import JSON

//do {
//    let source = "1+2"
//    print(source)
//    let core = Core(source: source)
//    let result = core.parse(LSumParser.start())
//    dump(result)
//    exit(0)
//}

enum ExitCode {
    static let inputAccepted: Int32 = 0
    static let inputRejected: Int32 = 1
    static let failure: Int32 = 2
}

let file: FileHandle
switch CommandLine.argc {
case 1:
    file = FileHandle.standardInput
case 2:
    guard let handle = FileHandle(forReadingAtPath: CommandLine.arguments[1])
    else { exit(ExitCode.failure) }
    file = handle
default:
    exit(ExitCode.failure)
}

guard let input = String(data: file.readDataToEndOfFile(), encoding: .utf8)
else { exit(ExitCode.failure) }

var core: Core<String>?
var result: Either<Mismatch, JSON>?

let stats = benchmark {
    core = Core(source: input)
    result = core?.parse(JSONParser.start())
}
print("Stats:\n  avg. user time: \(stats.avgUserTime) s\n  avg. sys  time: \(stats.avgSysTime) s")

//let core = GenericParserCore(source: input)
//let result = core.parse(JSONParser.start())
//
//dump(result)
//if let ff = core.farthestFailure {
//    let offset = input.distance(from: input.startIndex, to: ff.position)
//    print("\nMismatches at offset \(offset):\n")
//    ff.failures.forEach { f in
//        print("\(f.trace)\n\(f.mismatch)\n")
//    }
//}

if case .right? = result {
    print("ACCEPTED")
    exit(ExitCode.inputAccepted)
} else {
    if let report = core?.tracer.report() {
        print(report)
    }
    print("REJECTED")
    exit(ExitCode.inputRejected)
}
