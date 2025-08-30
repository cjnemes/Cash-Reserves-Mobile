// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ReserveEngine",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ReserveEngine", targets: ["ReserveEngine"])
    ],
    targets: [
        .target(name: "ReserveEngine")
    ]
)

