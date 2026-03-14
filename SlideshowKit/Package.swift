// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SlideshowKit",
    // Requires swift-tools-version 6.2+ for .v26 platform constants:
    // https://github.com/swiftlang/swift-package-manager/blob/main/Sources/PackageDescription/SupportedPlatforms.swift
    platforms: [.macOS(.v26), .iOS(.v26)],
    products: [
        .library(name: "SlideshowKit", targets: ["SlideshowKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "SlideshowKit",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .testTarget(
            name: "SlideshowKitTests",
            dependencies: ["SlideshowKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
