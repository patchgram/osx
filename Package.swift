// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Patchgram",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "PatchgramCore", targets: ["PatchgramCore"]),
        .executable(name: "patchgram", targets: ["Patchgram"])
    ],
    targets: [
        .target(
            name: "PatchgramCore",
            resources: [
                .copy("Resources/engine.c.template"),
                .copy("Resources/patches.json"),
                .copy("Resources/patch-manifest.json")
            ]
        ),
        .executableTarget(
            name: "Patchgram",
            dependencies: ["PatchgramCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PatchgramCoreTests",
            dependencies: ["PatchgramCore"]
        )
    ]
)
