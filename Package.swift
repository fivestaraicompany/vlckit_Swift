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
            publicHeadersPath: "include",
            linkerSettings: [
                // The prebuilt MobileVLCKit static archive has unresolved
                // references to libiconv (`_iconv*`) and the C++ runtime —
                // both ship with iOS but are not auto-linked by SPM, so
                // surface them here so consumer apps don't need OTHER_LDFLAGS.
                .linkedLibrary("iconv"),
                .linkedLibrary("c++"),
                .linkedLibrary("bz2"),
                .linkedLibrary("xml2"),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AudioToolbox", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("VideoToolbox", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreImage", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreVideo", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreMedia", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreText", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreGraphics", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("OpenGLES", .when(platforms: [.iOS])),
                .linkedFramework("QuartzCore", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("Security", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("SystemConfiguration", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS]))
            ]
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
