// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "VLCKit",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_15),
        .tvOS(.v12)
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
    targets: [
        .binaryTarget(
            name: "MobileVLCKit",
            url: "https://download.videolan.org/pub/cocoapods/prod/MobileVLCKit-3.7.2-3e42ae47-79128878.tar.xz",
            checksum: "77b867667e5e62aa4062e71b7a4f76a0e2f505425916091c0eb0f94d9ad4af80"
        ),
        .binaryTarget(
            name: "VLCKit",
            url: "https://download.videolan.org/pub/cocoapods/prod/VLCKit-3.7.2-3e42ae47-79128878.tar.xz",
            checksum: "45fc6398c80d1f8dc0e384a9c80704848e9e82a3a382611bf531fa83c198c276"
        ),
        .binaryTarget(
            name: "TVVLCKit",
            url: "https://download.videolan.org/cocoapods/prod/TVVLCKit-3.7.2-3e42ae47-79128878.tar.xz",
            checksum: "fa264c2eb17d648669d9d12b51e76e5b6769828354517d09b340387b30825f58"
        )
    ]
)
