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
        .target(
            name: "MobileVLCKit",
            path: "Sources",
            exclude: [
                // 불필요/충돌 가능 파일 제거
                "VLCMediaLibrary.m",
                "VLCMediaLibrary.swift",
                "VLCStaticLibVLC.m",
                "VLCStaticLibVVC.swift",
                "StaticLibVLC.m",
                "StaticLibVVC.swift",
                "VLCiOSLegacyDialogProvider.m",
                "VLCiOSLegacyDialogProvider.swift",
                "VLCEmbeddedDialogProvider.m",
                "VLCEmbeddedDialogProvider.swift",
                // macOS / tvOS 관련도 일단 제외
            ],
            publicHeadersPath: "Headers/Public",
            cSettings: [
                .headerSearchPath("Headers/Public")
            ]
        )
    ],
    cLanguageStandard: .c99,
    cxxLanguageStandard: .cxx14
)
