// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VLCKit",
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
            name: "VLCKit",
            targets: ["VLCKit"]
         ),
        .library(
            name: "TVVLCKit",
            targets: ["TVVLCKit"]
         )
       ],
    dependencies: [],
    targets: [
        .target(
            name: "libvlc",
            path: "libvlc",
            exclude: [
                  "COPYING",
                  "README.md"
               ]
           ),
        .target(
            name: "VLCKit",
            path: "Sources",
            exclude: [
                  "StaticLibVLC.m",
                  "VLCKitSwiftWrapper.h",
                  "VLCKitSwiftWrapper.m",
                  "VLCMediaPlayer+Swift.swift"
               ],
            publicHeadersPath: "Headers/Public"
           ),
        .target(
            name: "MobileVLCKitSwiftWrapper",
            dependencies: ["MobileVLCKit"],
            path: "Sources",
            sources: [
                  "VLCKitSwiftWrapper.h",
                  "VLCKitSwiftWrapper.m"
               ],
            publicHeadersPath: "."
           ),
        .target(
            name: "MobileVLCKit",
            dependencies: ["VLCKit", "libvlc", "MobileVLCKitSwiftWrapper"],
            path: "Sources",
            publicHeadersPath: "Headers/Public",
            cSettings: [
                  .headerSearchPath("Headers/Public"),
                  .headerSearchPath("Headers/Internal"),
                  .headerSearchPath("libvlc"),
                  .unsafeFlags([
                       "-DVLC_ENABLE_VIDEOTOOLS",
                       "-DVLC_ENABLE_IOS",
                       "-DVLC_ENABLE_MOBILE"
                   ])
               ],
            linkerSettings: [
                  .linkedFramework("AVFoundation"),
                  .linkedFramework("CoreGraphics"),
                  .linkedFramework("CoreMedia"),
                  .linkedFramework("CoreVideo"),
                  .linkedFramework("Foundation"),
                  .linkedFramework("MediaPlayer"),
                  .linkedFramework("MobileCoreServices"),
                  .linkedFramework("OpenAL"),
                  .linkedFramework("QuartzCore"),
                  .linkedFramework("SoundAnalysis"),
                  .linkedFramework("UIKit"),
                  .linkedFramework("VideoToolbox"),
                  .linkedLibrary("z"),
                  .linkedLibrary("iconv")
               ]
           ),
        .target(
            name: "TVVLCKitSwiftWrapper",
            dependencies: ["TVVLCKit"],
            path: "Sources",
            sources: [
                  "VLCKitSwiftWrapper.h",
                  "VLCKitSwiftWrapper.m"
               ],
            publicHeadersPath: "."
           ),
        .target(
            name: "TVVLCKit",
            dependencies: ["VLCKit", "libvlc", "TVVLCKitSwiftWrapper"],
            path: "Sources",
            publicHeadersPath: "Headers/Public",
            cSettings: [
                  .headerSearchPath("Headers/Public"),
                  .headerSearchPath("Headers/Internal"),
                  .headerSearchPath("libvlc"),
                  .unsafeFlags([
                       "-DVLC_ENABLE_TVOS",
                       "-DVLC_ENABLE_VIDEOTOOLS"
                   ])
               ],
            linkerSettings: [
                  .linkedFramework("AVFoundation"),
                  .linkedFramework("CoreGraphics"),
                  .linkedFramework("CoreMedia"),
                  .linkedFramework("CoreVideo"),
                  .linkedFramework("Foundation"),
                  .linkedFramework("UIKit"),
                  .linkedFramework("VideoToolbox")
               ]
           ),
        .testTarget(
            name: "VLCKitTests",
            dependencies: ["MobileVLCKit", "MobileVLCKitSwiftWrapper"],
            path: "Tests",
            exclude: [
                   "iOS"
               ],
            cSettings: [
                  .headerSearchPath("Headers/Public"),
                  .headerSearchPath("Sources")
               ]
           )
       ]
)
