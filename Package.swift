// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyBridges",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftyBridges",
            targets: ["SwiftyBridges"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", .revision("593d01f4017cf8b71ec28689629f7b9a6739df0b")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftyBridges",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]),
        .executableTarget(
            name: "BridgeBuilder",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]),
        .testTarget(
            name: "SwiftyBridgesTests",
            dependencies: ["SwiftyBridges"]),
    ]
)
