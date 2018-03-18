// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ParserCore",
    products: [
        .library(name: "ParserCore", targets: ["ParserCore"]),
        .library(name: "JSON", targets: ["JSON"]),
        .executable(name: "CLI", targets: ["CLI"])
    ],
    targets: [
        .target(
            name: "ParserCore"
        ),
        .target(
            name: "JSON",
            dependencies: ["ParserCore"]
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
