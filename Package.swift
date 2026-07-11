// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KeyCadence",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "KeyCadenceCore", targets: ["KeyCadenceCore"])
    ],
    targets: [
        .target(
            name: "KeyCadenceCore",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "KeyCadenceCoreTests",
            dependencies: ["KeyCadenceCore"],
            path: "Tests/KeyCadenceCoreTests"
        )
    ]
)
