// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "vlckit_Swift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "MobileVLCKit",
            targets: ["MobileVLCKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "MobileVLCKit",
            url: "https://github.com/fivestaraicompany/vlckit_Swift/releases/download/3.7.7/MobileVLCKit-3.7.6.xcframework.zip",
            checksum: "16bd3bdbf73589ef50391b034eff6c3496ad7f99f6832009857d0ee86733a46b"
        )
    ]
)
