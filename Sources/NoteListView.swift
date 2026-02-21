import SwiftUI

struct NoteListView: View {
    @EnvironmentObject private var noteStore: NoteStore
    @Binding var selectedNoteID: UUID?

    @State private var showingAddNote = false
    @State private var newNoteTitle = ""
    @State private var editingNote: Note?
    @State private var editingTitle = ""
    @State private var showingRenameAlert = false

    var body: some View {
        List(selection: $selectedNoteID) {
            ForEach(noteStore.notes) { note in
                noteRow(note: note)
                    .tag(note.id)
            }
            .onDelete { offsets in
                // Deselect if current note is deleted
                let deletedIDs = offsets.map { noteStore.notes[$0].id }
                if let selected = selectedNoteID, deletedIDs.contains(selected) {
                    selectedNoteID = nil
                }
                noteStore.deleteNotes(at: offsets)
            }
        }
        .navigationTitle("ノート")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .alert("新しいノートを作成", isPresented: $showingAddNote) {
            TextField("タイトル", text: $newNoteTitle)
            Button("作成") {
                noteStore.addNote(title: newNoteTitle.isEmpty ? "新しいノート" : newNoteTitle)
                newNoteTitle = ""
            }
            Button("キャンセル", role: .cancel) {
                newNoteTitle = ""
            }
        }
        .alert("名前を変更", isPresented: $showingRenameAlert) {
            TextField("タイトル", text: $editingTitle)
            Button("変更") {
                if let note = editingNote {
                    noteStore.renameNote(id: note.id, title: editingTitle)
                }
                editingNote = nil
            }
            Button("キャンセル", role: .cancel) {
                editingNote = nil
            }
        }
    }

    @ViewBuilder
    private func noteRow(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
            HStack {
                Label("\(note.pages.count)ページ", systemImage: "doc.text")
                Spacer()
                Text(note.updatedAt, style: .relative)
                    .foregroundStyle(.tertiary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let index = noteStore.notes.firstIndex(where: { $0.id == note.id }) {
                    if selectedNoteID == note.id { selectedNoteID = nil }
                    noteStore.deleteNotes(at: IndexSet([index]))
                }
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                editingNote = note
                editingTitle = note.title
                showingRenameAlert = true
            } label: {
                Label("名前変更", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}
