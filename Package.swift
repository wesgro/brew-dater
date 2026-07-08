// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BrewMenu",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "BrewCore"
        ),
        .executableTarget(
            name: "BrewMenuApp",
            dependencies: ["BrewCore"]
        ),
        .executableTarget(
            name: "BrewCoreVerify",
            dependencies: ["BrewCore"]
        ),
    ]
)
