import SwiftUI

struct ContentView: View {
    @Environment(NoteStore.self) private var noteStore
    @State private var selectedNoteID: UUID?

    var body: some View {
        NavigationSplitView {
            NoteListView(selectedNoteID: $selectedNoteID)
        } detail: {
            if let noteID = selectedNoteID,
               noteStore.notes.contains(where: { $0.id == noteID }) {
                NoteDetailView(noteID: noteID)
            } else {
                ContentUnavailableView(
                    "ノートを選択",
                    systemImage: "note.text",
                    description: Text("左のリストからノートを選んでください")
                )
            }
        }
    }
}
