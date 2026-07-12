// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Keymit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "KeymitCore", targets: ["KeymitCore"])
    ],
    targets: [
        .target(
            name: "KeymitCore",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "KeymitCoreTests",
            dependencies: ["KeymitCore"],
            path: "Tests/KeymitCoreTests"
        )
    ]
)
