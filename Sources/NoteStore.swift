import Foundation
import PencilKit

final class NoteStore: ObservableObject {

    @Published var notes: [Note] = []

    private let saveKey = "notepad_notes_v1"

    init() {
        load()
        if notes.isEmpty {
            notes.append(Note(title: "ノート 1"))
        }
    }

    // MARK: - Note CRUD

    func addNote(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        notes.append(Note(title: trimmed.isEmpty ? "新しいノート" : trimmed))
        save()
    }

    func deleteNotes(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        save()
    }

    func renameNote(id: UUID, title: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        notes[index].title = trimmed.isEmpty ? "新しいノート" : trimmed
        notes[index].updatedAt = Date()
        save()
    }

    // MARK: - Page CRUD

    func addPage(to noteID: UUID, after pageIndex: Int? = nil) {
        guard let noteIndex = notes.firstIndex(where: { $0.id == noteID }) else { return }
        let newPage = Page()
        if let pageIndex {
            let insertAt = min(pageIndex + 1, notes[noteIndex].pages.count)
            notes[noteIndex].pages.insert(newPage, at: insertAt)
        } else {
            notes[noteIndex].pages.append(newPage)
        }
        notes[noteIndex].updatedAt = Date()
        save()
    }

    func deletePage(at pageIndex: Int, in noteID: UUID) {
        guard let noteIndex = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard notes[noteIndex].pages.count > 1 else { return }
        notes[noteIndex].pages.remove(at: pageIndex)
        notes[noteIndex].updatedAt = Date()
        save()
    }

    func updateDrawing(_ drawing: PKDrawing, noteID: UUID, pageIndex: Int) {
        guard let noteIndex = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard pageIndex < notes[noteIndex].pages.count else { return }
        notes[noteIndex].pages[pageIndex].drawing = drawing
        notes[noteIndex].updatedAt = Date()
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else { return }
        notes = decoded
    }
}
