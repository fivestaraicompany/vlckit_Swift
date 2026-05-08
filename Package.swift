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
            url: "https://github.com/fivestaraicompany/vlckit_Swift/releases/download/5.0.4/MobileVLCKit-5.0.4.xcframework.zip",
            checksum: "37c7aae021669e403a38523c6072ef064c27817b0530ef1c3109fac1e784627c"
        ),
        .target(
            name: "CLibVLC",
            dependencies: ["MobileVLCKit"],
            path: "Sources/CLibVLC",
            publicHeadersPath: "include"
        ),
        .target(
            name: "VLCKitSwift",
            dependencies: ["MobileVLCKit", "CLibVLC"],
            path: "Sources/Swift",
            exclude: [
                "VLC_Helper_Code.swift",
                "VCL_Lib_VLC_Bridging.swift"
            ]
        ),
        .testTarget(
            name: "VLCKitTests",
            dependencies: ["VLCKitSwift"],
            path: "Tests/VLCKitTests"
        )
    ]
)
