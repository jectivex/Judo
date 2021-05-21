// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Judo",
    products: [
        .library(
            name: "Judo",
            targets: ["Judo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jectivex/SwiftJS.git", .branch("main")),
        .package(url: "https://github.com/glimpseio/BricBrac.git", .branch("main")),
        .package(url: "https://github.com/glimpseio/MiscKit.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "Judo",
            dependencies: ["MiscKit", "SwiftJS", "BricBrac"],
            resources: [.copy("Resources")]),
        .testTarget(
            name: "JudoTests",
            dependencies: ["Judo"],
            resources: [.copy("Resources")]),
    ]
)
