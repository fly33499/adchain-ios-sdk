// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "AdchainSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AdchainSDK",
            targets: ["AdchainSDK"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AdchainSDK",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AdchainSDKTests",
            dependencies: ["AdchainSDK"],
            path: "Tests"
        )
    ]
)