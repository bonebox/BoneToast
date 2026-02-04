// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BoneToast",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "BoneToast",
            targets: ["BoneToast"]
        ),
    ],
    targets: [
        .target(
            name: "BoneToast"
        ),
        .testTarget(
            name: "BoneToastTests",
            dependencies: ["BoneToast"]
        ),
    ]
)
