// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ParserCore",
    products: [
        .library(name: "ParserCore", targets: ["ParserCore"]),
        .library(name: "ParserCore2", targets: ["ParserCore2"]),
        .library(name: "JSON", targets: ["JSON"]),
        .executable(name: "CLI", targets: ["CLI"])
    ],
    targets: [
        .target(
            name: "ParserCore"
        ),
        .target(
            name: "ParserCore2"
        ),
        .target(
            name: "JSON",
            dependencies: ["ParserCore", "ParserCore2"]
        ),
        .target(
            name: "ThreadTime"
        ),
        .target(
            name: "CLI",
            dependencies: ["ParserCore", "JSON", "ThreadTime"]
        )
    ]
)
