import SwiftUI

@main
struct NotepadApp: App {
    @State private var noteStore = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(noteStore)
        }
    }
}
