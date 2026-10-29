// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AntCloudMac",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.1.1"),
    ],
    targets: [
        // Sources/Shared is also compiled directly into the iOS app (../AntCloudiOS).
        .executableTarget(
            name: "AntCloud",
            dependencies: [.product(name: "SocketIO", package: "socket.io-client-swift")],
            path: "Sources",
            sources: ["Mac", "Shared"]
        ),
    ]
)
