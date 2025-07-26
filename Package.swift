// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "screenit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "screenit",
            targets: ["screenit"]
        ),
    ],
    dependencies: [
        // No external dependencies - using only Apple frameworks
    ],
    targets: [
        .executableTarget(
            name: "screenit",
            dependencies: [],
            path: "screenit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "screenitTests",
            dependencies: ["screenit"],
            path: "screenitTests"
        ),
    ]
)