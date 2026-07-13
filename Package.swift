// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HeliumCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HeliumCore", targets: ["HeliumCore"])
    ],
    targets: [
        .target(
            name: "HeliumCore",
            path: "Core/Sources/HeliumCore"
        ),
        .testTarget(
            name: "HeliumCoreTests",
            dependencies: ["HeliumCore"],
            path: "Core/Tests/HeliumCoreTests"
        )
    ]
)
