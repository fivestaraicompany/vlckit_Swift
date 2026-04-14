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
        ),
        .library(
            name: "VLCKitSwift",
            type: .dynamic,
            targets: ["VLCKitSwift"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "MobileVLCKit",
            url: "https://github.com/fivestaraicompany/vlckit_Swift/releases/download/3.7.9/MobileVLCKit-3.7.8.xcframework.zip",
            checksum: "6e3d3ef2e36f397b70face072008942ebcc189f4d554258747a002aa236a9750"
        ),
        .target(
            name: "VLCKitSwift",
            dependencies: ["MobileVLCKit"],
            path: "Sources/Swift",
            exclude: [
                "VLC_Helper_Code.swift",
                "VCL_Lib_VLC_Bridging.swift"
            ],
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "VLCKitTests",
            dependencies: ["VLCKitSwift"],
            path: "Tests/VLCKitTests"
        )
    ]
)
