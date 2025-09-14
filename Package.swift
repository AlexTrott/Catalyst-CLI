// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Catalyst",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "catalyst",
            targets: ["CatalystCLI"]
        ),
        .library(
            name: "CatalystCore",
            targets: ["CatalystCore"]
        )
    ],
    dependencies: [
        // Command-line argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),

        // YAML parsing for configuration files
        .package(url: "https://github.com/jpsim/Yams", from: "6.1.0"),

        // File system operations
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),

        // Colorful terminal output
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0"),

        // Template engine
        .package(url: "https://github.com/stencilproject/Stencil", from: "0.15.1"),

        // Xcodeproj/xcworkspace manipulation
        .package(url: "https://github.com/tuist/XcodeProj", from: "9.5.0"),

        // Shell command execution
        .package(url: "https://github.com/kareman/SwiftShell", from: "5.1.0"),

        // Modern file system API
        .package(url: "https://github.com/JohnSundell/Files", from: "4.3.0")
    ],
    targets: [
        // Main executable target
        .executableTarget(
            name: "CatalystCLI",
            dependencies: [
                "CatalystCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),

        // Core library target
        .target(
            name: "CatalystCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "TemplateEngine",
                "WorkspaceManager",
                "PackageGenerator",
                "MicroAppGenerator",
                "ConfigurationManager",
                "Utilities"
            ]
        ),

        // Template Engine module
        .target(
            name: "TemplateEngine",
            dependencies: [
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Files", package: "Files")
            ]
        ),

        // Workspace Manager module
        .target(
            name: "WorkspaceManager",
            dependencies: [
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Files", package: "Files")
            ]
        ),

        // MicroApp Generator module
        .target(
            name: "MicroAppGenerator",
            dependencies: [
                "TemplateEngine",
                .product(name: "SwiftShell", package: "SwiftShell"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Files", package: "Files"),
                .product(name: "Yams", package: "Yams")
            ]
        ),

        // Package Generator module
        .target(
            name: "PackageGenerator",
            dependencies: [
                "TemplateEngine",
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Files", package: "Files")
            ]
        ),

        // Configuration Manager module
        .target(
            name: "ConfigurationManager",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Files", package: "Files")
            ]
        ),

        // Utilities module
        .target(
            name: "Utilities",
            dependencies: [
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "SwiftShell", package: "SwiftShell"),
                .product(name: "Files", package: "Files")
            ]
        ),

        // Test targets
        .testTarget(
            name: "CatalystCoreTests",
            dependencies: ["CatalystCore"]
        ),
        .testTarget(
            name: "TemplateEngineTests",
            dependencies: ["TemplateEngine"]
        ),
        .testTarget(
            name: "WorkspaceManagerTests",
            dependencies: ["WorkspaceManager"]
        ),
        .testTarget(
            name: "PackageGeneratorTests",
            dependencies: ["PackageGenerator"]
        )
    ]
)
