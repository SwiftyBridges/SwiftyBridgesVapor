// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "SwiftyBridges",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftyBridges",
            targets: ["SwiftyBridges"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", .revision("593d01f4017cf8b71ec28689629f7b9a6739df0b")),
//        .package(url: "https://github.com/stencilproject/Stencil.git", .upToNextMinor(from: "0.14.1")),
        .package(url: "https://github.com/dusi/Stencil.git", .branch("master")),
//        .package(url: "https://github.com/SwiftGen/StencilSwiftKit", from: "2.8.0"),
        .package(url: "https://github.com/dusi/StencilSwiftKit.git", .revision("549ed927fcf0ff980193eba54ddd62583628e3b4"))
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
                .product(name: "SwiftSyntax", package: "swift-syntax"),
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
