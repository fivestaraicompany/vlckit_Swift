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
            url: "https://github.com/fivestaraicompany/vlckit_Swift/releases/download/5.0.6/MobileVLCKit-5.0.6.xcframework.zip",
            checksum: "0949055eac276f2b861c6b4b63acf1e081515761cbfdd81d458c79bbca1d02c6"
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
