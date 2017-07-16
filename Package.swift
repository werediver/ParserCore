// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "ParserCore",
    targets: [
        Target(
            name: "ParserCore"
        ),
        Target(
            name: "CLI",
            dependencies: ["ParserCore"]
        )
    ]
)
