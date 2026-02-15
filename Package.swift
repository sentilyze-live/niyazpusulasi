// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NiyazPusulasi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NiyazPusulasi", targets: ["NiyazPusulasi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift.git", from: "1.4.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "NiyazPusulasi",
            dependencies: [
                .product(name: "Adhan", package: "adhan-swift"),
                .product(name: "RevenueCat", package: "purchases-ios"),
            ],
            path: "NiyazPusulasi",
            exclude: [
                "Resources/Assets.xcassets",
                "Models/CoreData/NiyazPusulasi.xcdatamodeld",
                "Info.plist",
                "NiyazPusulasi.entitlements",
            ]
        ),
        .testTarget(
            name: "NiyazPusulasTests",
            dependencies: ["NiyazPusulasi"],
            path: "NiyazPusulasTests"
        ),
    ]
)
