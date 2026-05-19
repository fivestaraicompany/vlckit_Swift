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
            sources: [
                "Audio",
                "Core",
                "Dialogs",
                "Events",
                "Filters",
                "Helpers",
                "Logging",
                "Media",
                "Modules",
                "Playback",
                "Renderer",
                "SwiftHeaders",
                "Tools",
                "Video",
                "sout"
            ],
            linkerSettings: [
                   .linkedFramework("Metal", .when(platforms: [.iOS, .macOS, .tvOS])),
                   .linkedFramework("CoreVideo", .when(platforms: [.iOS, .macOS, .tvOS, .watchOS])),
                   .linkedFramework("QuartzCore", .when(platforms: [.iOS, .macOS, .tvOS, .watchOS])),
                   .linkedFramework("AppKit", .when(platforms: [.macOS])),
                   .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                   .linkedFramework("MetalKit", .when(platforms: [.iOS, .tvOS])),
               ]
           ),
       ]
)
