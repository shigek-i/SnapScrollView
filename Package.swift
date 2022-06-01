// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SnapScrollView",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SnapScrollView",
            targets: ["SnapScrollView"]),
    ],
    targets: [
        .target(
            name: "SnapScrollView",
            dependencies: []),
    ]
)
