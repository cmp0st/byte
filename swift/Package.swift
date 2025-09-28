// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ByteClient",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "ByteClient",
            targets: ["ByteClient"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/connectrpc/connect-swift", from: "0.12.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.26.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/aidantwoods/swift-paseto.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "ByteClient",
            dependencies: [
                .product(name: "Connect", package: "connect-swift"),
                .product(name: "ConnectMocks", package: "connect-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Paseto", package: "swift-paseto"),
            ]
        ),
        .testTarget(
            name: "ByteClientTests",
            dependencies: ["ByteClient"]
        ),
    ]
)
