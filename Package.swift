// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "SwiftyBridgesVapor",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftyBridges",
            targets: ["SwiftyBridges"]),
        .executable(
            name: "BridgeBuilder",
            targets: ["BridgeBuilder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50500.0")),
        .package(url: "https://github.com/stencilproject/Stencil.git", .upToNextMinor(from: "0.14.1")),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit", from: "2.8.0"),
    ],
    targets: [
        .target(
            name: "SwiftyBridges",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .executableTarget(
            name: "BridgeBuilder",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "StencilSwiftKit", package: "StencilSwiftKit"),
            ],
            resources: [
                .copy("Templates")
            ]
        ),
        .testTarget(
            name: "SwiftyBridgesTests",
            dependencies: ["SwiftyBridges"]
        ),
    ]
)
