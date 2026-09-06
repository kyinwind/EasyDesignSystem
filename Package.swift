// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyDesignSystem",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EasyDesignSystem",
            targets: ["EasyDesignSystem"]
        ),
        .library(
            name: "EasyDesignSystemCatalog",
            targets: ["EasyDesignSystemCatalog"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "EasyDesignSystem",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "EasyDesignSystemCatalog",
            dependencies: ["EasyDesignSystem"],
            path: "Examples/Catalog"
        ),
        .testTarget(
            name: "EasyDesignSystemTests",
            dependencies: ["EasyDesignSystem"],
            resources: [
                .process("Fixtures")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
