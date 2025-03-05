// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "eventide",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "eventide", targets: ["eventide"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "eventide",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
