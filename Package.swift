// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Judo",
    products: [
        .library(
            name: "Judo",
            targets: ["Judo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jectivex/JXKit.git", .branch("main")),
        .package(url: "https://github.com/glimpseio/BricBrac.git", .branch("main")),
        .package(url: "https://github.com/glimpseio/MiscKit.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "Judo",
            dependencies: ["MiscKit", "JXKit", "BricBrac"],
            resources: [.copy("Resources")]),
        .testTarget(
            name: "JudoTests",
            dependencies: ["Judo"],
            resources: [.copy("Resources")]),
    ]
)
