// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "V2EX",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "V2EX",
            targets: ["V2EX"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "V2EX",
            dependencies: [],
            path: "V2EX")
    ]
)
