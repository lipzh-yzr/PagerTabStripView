// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PagerTabStripView",
    platforms: [.iOS(.v15), .macOS(.v14)],
    products: [
        .library(name: "PagerTabStripView", targets: ["PagerTabStripView"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", from: "0.3.0"),
        .package(
            url: "https://github.com/pointfreeco/swift-perception",
            exact: "2.0.10"
        )
    ],
    targets: [
        .target(
            name: "PagerTabStripView",
            dependencies: [
                .product(name: "Perception", package: "swift-perception"),
                .product(name: "SwiftUIX", package: "SwiftUIX")
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
