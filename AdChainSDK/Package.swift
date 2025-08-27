// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "AdChainSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AdChainSDK",
            targets: ["AdChainSDK"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AdChainSDK",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AdChainSDKTests",
            dependencies: ["AdChainSDK"],
            path: "Tests"
        )
    ]
)