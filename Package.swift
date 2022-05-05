// swift-tools-version:5.6

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
        .plugin(
            name: "APICodeGenerator",
            targets: ["APICodeGenerator"]),
        .plugin(
            name: "XcodeBridgeHelper",
            targets: ["XcodeBridgeHelper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "0.50600.1"),
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
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "StencilSwiftKit", package: "StencilSwiftKit"),
                "lib_InternalSwiftSyntaxParser",
            ],
            resources: [
                .copy("Templates")
            ],
            // `-dead_strip_dylibs` is passed because we want to use the version of lib_InternalSwiftSyntaxParser from StaticInternalSwiftSyntaxParser.
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-dead_strip_dylibs"])
            ]
        ),
        .testTarget(
            name: "SwiftyBridgesTests",
            dependencies: ["SwiftyBridges"]
        ),
        .binaryTarget(
            name: "lib_InternalSwiftSyntaxParser",
            url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/5.6/lib_InternalSwiftSyntaxParser.xcframework.zip",
            checksum: "88d748f76ec45880a8250438bd68e5d6ba716c8042f520998a438db87083ae9d"
        ),
        .plugin(
            name: "APICodeGenerator",
            capability: .buildTool(),
            dependencies: ["BridgeBuilder"]
        ),
        .plugin(
            name: "XcodeBridgeHelper",
            capability: .command(
                intent: .custom(
                    verb: "xcode-bridge-helper",
                    description: """
                        This command is intended to be called in an Xcode post-build script to surface the generated API client code. To use it, add the following script as a post-build script to the main scheme of your package in Xcode and be sure to select the 'App' target under 'Provide build settings from':
                        
                        # This script is needed to ensure that the API client code generated by SwiftyBridges is updated and made accessible each time the server code is updated and built. After building, you can find it under 'GeneratedClientCode' inside the package directory.
                        cd $WORKSPACE_PATH
                        swift package --disable-sandbox xcode-bridge-helper
                        
                        """
                )
            )
        ),
    ]
)
