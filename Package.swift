// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GoalPyramid",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "GoalPyramid",
            path: "Sources/GoalPyramid"
        )
    ]
)
