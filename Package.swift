// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "Notepad",
    platforms: [
        .iOS("17.0")
    ],
    targets: [
        .executableTarget(
            name: "Notepad"
        )
    ]
)
