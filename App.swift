import SwiftUI

@main
struct NotepadApp: App {
    @StateObject private var noteStore = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(noteStore)
        }
    }
}
