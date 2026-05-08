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
            name: "MobileVLCKitBinary",
            url: "https://github.com/fivestaraicompany/vlckit_Swift/releases/download/5.0.5/MobileVLCKit-5.0.5.xcframework.zip",
            checksum: "707e92dbf99ed5b632b2598a96cc1b1a4c776aa463d988f29860fb36e5cd75fa"
        ),
        .target(
            name: "CLibVLC",
            dependencies: ["MobileVLCKitBinary"],
            path: "Sources/CLibVLC",
            publicHeadersPath: "include"
        ),
        .target(
            name: "MobileVLCKit",
            dependencies: ["MobileVLCKitBinary", "CLibVLC"],
            path: "Sources/Swift",
            exclude: [
                "VLC_Helper_Code.swift",
                "VCL_Lib_VLC_Bridging.swift"
            ]
        ),
        .testTarget(
            name: "VLCKitTests",
            dependencies: ["MobileVLCKit"],
            path: "Tests/VLCKitTests"
        )
    ]
)
