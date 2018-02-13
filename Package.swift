// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ParserCore",
    products: [
        .library(name: "ParserCore", targets: ["ParserCore"]),
        .executable(name: "CLI", targets: ["CLI"])
    ],
    targets: [
        .target(
            name: "ParserCore"
        ),
        .target(
            name: "CLI",
            dependencies: ["ParserCore"]
        )
    ]
)
