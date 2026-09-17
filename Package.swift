// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FreeLLMKeyManager",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "FreeLLMKeyManager"),
        .testTarget(name: "FreeLLMKeyManagerTests", dependencies: ["FreeLLMKeyManager"])
    ]
)
