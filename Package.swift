// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VLCKit",
    platforms: [
         .iOS(.v13),
         .macOS(.v10_15),
         .tvOS(.v13),
         .watchOS(.v6)
     ],
    products: [
         .library(
            name: "VLCKit",
            targets: ["VLCKit"]
         ),
     ],
    targets: [
         .target(
            name: "VLCKit",
            dependencies: [],
            path: "Sources",
            publicHeaders: "SwiftHeaders/Public",
            cSettings: [
                 .headerSearchPath("../Headers/Public"),
                 .headerSearchPath("../Headers/Public/Audio"),
                 .headerSearchPath("../Headers/Public/Filters"),
                 .headerSearchPath("../Headers/Public/Logging"),
                 .headerSearchPath("../Headers/Public/Media"),
                 .headerSearchPath("../Headers/Public/Playback"),
                 .headerSearchPath("../Headers/Public/Renderer"),
                 .headerSearchPath("../Headers/Public/Tools"),
                 .headerSearchPath("../Headers/Public/Video"),
                 .headerSearchPath("../Headers/Public/sout"),
                 .headerSearchPath("../Headers/Internal"),
                 .headerSearchPath("../../libvlc"),
                 .headerSearchPath("Modules"),
                 .define("TARGET_OS_IOS", to: "1", .when(platforms: [.iOS])),
                 .define("TARGET_OS_OSX", to: "1", .when(platforms: [.macOS])),
                 .define("TARGET_OS_TV", to: "1", .when(platforms: [.tvOS])),
                 .define("TARGET_OS_WATCH", to: "1", .when(platforms: [.watchOS])),
             ]
         ),
     ]
)
