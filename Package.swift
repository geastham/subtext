// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Subtext",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Subtext",
            targets: ["Subtext"]),
    ],
    targets: [
        .target(
            name: "Subtext",
            dependencies: [],
            path: "Subtext"
        ),
        .testTarget(
            name: "SubtextTests",
            dependencies: ["Subtext"]
        ),
    ]
)

