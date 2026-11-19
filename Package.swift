// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "LidHarbor",
    platforms: [.macOS(.v13)],
    products: [.library(name: "LidHarborCore", targets: ["LidHarborCore"]), .executable(name: "lidharbor-demo", targets: ["LidHarborDemo"])],
    targets: [
        .target(name: "LidHarborCore"),
        .executableTarget(name: "LidHarborDemo", dependencies: ["LidHarborCore"]),
        .testTarget(name: "LidHarborCoreTests", dependencies: ["LidHarborCore"])
    ]
)
