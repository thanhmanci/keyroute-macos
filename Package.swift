// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "keyroute",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "KeyRouteKit", targets: ["KeyRouteKit"]),
        .executable(name: "KeyRoute", targets: ["KeyRoute"]),
        .executable(name: "keyroutectl", targets: ["keyroutectl"]),
        .executable(name: "keyroute-selftest", targets: ["keyroute-selftest"])
    ],
    targets: [
        .target(name: "KeyRouteKit"),
        .executableTarget(
            name: "KeyRoute",
            dependencies: ["KeyRouteKit"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon")
            ]
        ),
        .executableTarget(
            name: "keyroutectl",
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        ),
        .executableTarget(
            name: "keyroute-selftest",
            dependencies: ["KeyRouteKit"]
        )
    ]
)
