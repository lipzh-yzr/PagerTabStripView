// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PagerTabStripView",
    platforms: [.iOS(.v15), .macOS(.v14)],
    products: [
        .library(name: "PagerTabStripView", targets: ["PagerTabStripView"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "PagerTabStripView",
            dependencies: [
                .product(name: "Perception", package: "swift-perception")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PagerTabStripViewTests",
            dependencies: ["PagerTabStripView"],
            path: "PagerTabStripViewTests",
            linkerSettings: [
                .linkedFramework("CoreGraphics", .when(platforms: [.macOS, .iOS])),
                .linkedFramework("Foundation", .when(platforms: [.macOS, .iOS]))
            ]
        )
    ]
)
