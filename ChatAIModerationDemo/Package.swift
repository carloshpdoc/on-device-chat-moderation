// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChatAIModerationDemo",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "ChatAIModerationDemo",
            targets: ["ChatAIModerationDemo"]
        )
    ],
    dependencies: [
        .package(path: "../ChatAICore")
    ],
    targets: [
        .executableTarget(
            name: "ChatAIModerationDemo",
            dependencies: [
                .product(name: "ChatAICore", package: "ChatAICore")
            ],
            path: "Sources"
        )
    ]
)
