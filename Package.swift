// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Notepad",
    platforms: [
        .iOS("18.0")
    ],
    targets: [
        .executableTarget(
            name: "Notepad",
            path: "."
        )
    ]
)
