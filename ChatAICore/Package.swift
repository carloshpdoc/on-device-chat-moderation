
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChatAICore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ChatAICore",
            targets: ["ChatAICore"]
        ),
    ],
    targets: [
        .target(
            name: "ChatAICore",
            resources: [
                .process("Resources/ModerationPolicy.json")
            ]
        ),
        .testTarget(
            name: "ChatAICoreTests",
            dependencies: ["ChatAICore"]
        ),
    ]
)
