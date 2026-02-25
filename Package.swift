// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notepad",
    platforms: [
        .iOS("17.0")
    ],
    targets: [
        .executableTarget(
            name: "Notepad",
            path: ".",
            sources: [
                "App.swift",
                "Models.swift",
                "NoteStore.swift",
                "ContentView.swift",
                "NoteListView.swift",
                "NoteDetailView.swift",
                "CanvasView.swift",
                "DrawingToolbarView.swift",
                "PageNavigationView.swift"
            ]
        )
    ]
)
