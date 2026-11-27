// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "eventide_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "eventide-ios",
            targets: ["eventide_ios"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "eventide_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "EventideTests",
            dependencies: ["eventide_ios"],
            path: "Tests/EventideTests"
        ),
    ]
)
