// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QRski",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "CQREncode",
            path: "Sources/CQREncode",
            publicHeadersPath: ".",
            cSettings: [
                .define("STATIC_IN_RELEASE", to: ""),
                .define("MAJOR_VERSION", to: "4"),
                .define("MINOR_VERSION", to: "1"),
                .define("MICRO_VERSION", to: "1"),
                .define("VERSION", to: "\"4.1.1\"")
            ]
        ),
        .executableTarget(
            name: "QRski",
            dependencies: ["CQREncode"],
            path: "Sources/QRski",
            resources: [.process("Assets.xcassets")]
        ),
    ],
    swiftLanguageModes: [.v5]
)
