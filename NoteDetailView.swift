import SwiftUI
import PencilKit

struct NoteDetailView: View {
    @Environment(NoteStore.self) private var noteStore
    let noteID: UUID

    @State private var currentPageIndex: Int = 0
    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: DrawingColor = .black
    @State private var selectedThickness: DrawingThickness = .medium

    var body: some View {
        if let note = noteStore.notes.first(where: { $0.id == noteID }) {
            noteContent(note: note)
                .navigationTitle(note.title)
                .navigationBarTitleDisplayMode(.inline)
                .onChange(of: note.pages.count) { _, newCount in
                    if currentPageIndex >= newCount {
                        currentPageIndex = max(0, newCount - 1)
                    }
                }
        }
    }

    @ViewBuilder
    private func noteContent(note: Note) -> some View {
        let pageIdx = min(currentPageIndex, note.pages.count - 1)

        VStack(spacing: 0) {
            // Drawing toolbar
            DrawingToolbarView(
                selectedTool: $selectedTool,
                selectedColor: $selectedColor,
                selectedThickness: $selectedThickness
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .overlay(alignment: .bottom) {
                Divider()
            }

            // Canvas
            CanvasView(
                drawing: Binding(
                    get: {
                        guard let n = noteStore.notes.first(where: { $0.id == noteID }),
                              pageIdx < n.pages.count
                        else { return PKDrawing() }
                        return n.pages[pageIdx].drawing
                    },
                    set: { newDrawing in
                        noteStore.updateDrawing(newDrawing, noteID: noteID, pageIndex: pageIdx)
                    }
                ),
                tool: selectedTool,
                color: selectedColor,
                thickness: selectedThickness
            )
            // Force CanvasView to recreate when the page changes
            .id(note.pages[pageIdx].id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)

            Divider()

            // Page navigation strip
            PageNavigationView(
                noteID: noteID,
                currentPageIndex: $currentPageIndex
            )
        }
    }
}
