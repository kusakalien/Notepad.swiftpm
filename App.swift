import SwiftUI
import Foundation
import PencilKit

// MARK: - Entry Point

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

// MARK: - Models

struct Note: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var pages: [Page]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String = "新しいノート") {
        self.title = title
        self.pages = [Page()]
    }
}

struct Page: Identifiable, Codable {
    var id: UUID = UUID()
    var drawingData: Data = Data()
    var createdAt: Date = Date()

    var drawing: PKDrawing {
        get { (try? PKDrawing(data: drawingData)) ?? PKDrawing() }
        set { drawingData = (try? newValue.dataRepresentation()) ?? Data() }
    }
}

enum DrawingTool: Equatable {
    case pen
    case eraser
}

enum DrawingColor: CaseIterable, Equatable {
    case black, red, blue

    var uiColor: UIColor {
        switch self {
        case .black: return .black
        case .red:   return .systemRed
        case .blue:  return .systemBlue
        }
    }

    var color: Color { Color(uiColor: uiColor) }

    var name: String {
        switch self {
        case .black: return "黒"
        case .red:   return "赤"
        case .blue:  return "青"
        }
    }
}

enum DrawingThickness: CaseIterable, Equatable {
    case thin, medium, thick

    var penWidth: CGFloat {
        switch self { case .thin: return 2; case .medium: return 5; case .thick: return 12 }
    }
    var eraserWidth: CGFloat {
        switch self { case .thin: return 20; case .medium: return 50; case .thick: return 100 }
    }
    var dotSize: CGFloat {
        switch self { case .thin: return 6; case .medium: return 11; case .thick: return 18 }
    }
    var label: String {
        switch self { case .thin: return "細"; case .medium: return "中"; case .thick: return "太" }
    }
}

// MARK: - NoteStore

@MainActor
final class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    private let saveKey = "notepad_notes_v1"

    init() {
        load()
        if notes.isEmpty { notes.append(Note(title: "ノート 1")) }
    }

    func addNote(title: String) {
        let t = title.trimmingCharacters(in: .whitespaces)
        notes.append(Note(title: t.isEmpty ? "新しいノート" : t))
        save()
    }

    func deleteNotes(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        save()
    }

    func renameNote(id: UUID, title: String) {
        guard let i = notes.firstIndex(where: { $0.id == id }) else { return }
        let t = title.trimmingCharacters(in: .whitespaces)
        notes[i].title = t.isEmpty ? "新しいノート" : t
        notes[i].updatedAt = Date()
        save()
    }

    func addPage(to noteID: UUID, after pageIndex: Int? = nil) {
        guard let i = notes.firstIndex(where: { $0.id == noteID }) else { return }
        let newPage = Page()
        if let idx = pageIndex {
            notes[i].pages.insert(newPage, at: min(idx + 1, notes[i].pages.count))
        } else {
            notes[i].pages.append(newPage)
        }
        notes[i].updatedAt = Date()
        save()
    }

    func deletePage(at pageIndex: Int, in noteID: UUID) {
        guard let i = notes.firstIndex(where: { $0.id == noteID }),
              notes[i].pages.count > 1 else { return }
        notes[i].pages.remove(at: pageIndex)
        notes[i].updatedAt = Date()
        save()
    }

    func updateDrawing(_ drawing: PKDrawing, noteID: UUID, pageIndex: Int) {
        guard let i = notes.firstIndex(where: { $0.id == noteID }),
              pageIndex < notes[i].pages.count else { return }
        notes[i].pages[pageIndex].drawing = drawing
        notes[i].updatedAt = Date()
        save()
    }

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

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var noteStore: NoteStore
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

// MARK: - NoteListView

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
                noteRow(note: note).tag(note.id)
            }
            .onDelete { offsets in
                let ids = offsets.map { noteStore.notes[$0].id }
                if let sel = selectedNoteID, ids.contains(sel) { selectedNoteID = nil }
                noteStore.deleteNotes(at: offsets)
            }
        }
        .navigationTitle("ノート")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddNote = true } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) { EditButton() }
        }
        .alert("新しいノートを作成", isPresented: $showingAddNote) {
            TextField("タイトル", text: $newNoteTitle)
            Button("作成") {
                noteStore.addNote(title: newNoteTitle.isEmpty ? "新しいノート" : newNoteTitle)
                newNoteTitle = ""
            }
            Button("キャンセル", role: .cancel) { newNoteTitle = "" }
        }
        .alert("名前を変更", isPresented: $showingRenameAlert) {
            TextField("タイトル", text: $editingTitle)
            Button("変更") {
                if let note = editingNote { noteStore.renameNote(id: note.id, title: editingTitle) }
                editingNote = nil
            }
            Button("キャンセル", role: .cancel) { editingNote = nil }
        }
    }

    @ViewBuilder
    private func noteRow(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title).font(.headline)
            HStack {
                Label("\(note.pages.count)ページ", systemImage: "doc.text")
                Spacer()
                Text(note.updatedAt, style: .relative).foregroundStyle(.tertiary)
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let idx = noteStore.notes.firstIndex(where: { $0.id == note.id }) {
                    if selectedNoteID == note.id { selectedNoteID = nil }
                    noteStore.deleteNotes(at: IndexSet([idx]))
                }
            } label: { Label("削除", systemImage: "trash") }
        }
        .swipeActions(edge: .leading) {
            Button {
                editingNote = note
                editingTitle = note.title
                showingRenameAlert = true
            } label: { Label("名前変更", systemImage: "pencil") }
            .tint(.blue)
        }
    }
}

// MARK: - NoteDetailView

struct NoteDetailView: View {
    @EnvironmentObject private var noteStore: NoteStore
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
            DrawingToolbarView(
                selectedTool: $selectedTool,
                selectedColor: $selectedColor,
                selectedThickness: $selectedThickness
            )
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .overlay(alignment: .bottom) { Divider() }

            CanvasView(
                drawing: Binding(
                    get: {
                        guard let n = noteStore.notes.first(where: { $0.id == noteID }),
                              pageIdx < n.pages.count else { return PKDrawing() }
                        return n.pages[pageIdx].drawing
                    },
                    set: { noteStore.updateDrawing($0, noteID: noteID, pageIndex: pageIdx) }
                ),
                tool: selectedTool,
                color: selectedColor,
                thickness: selectedThickness
            )
            .id(note.pages[pageIdx].id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)

            Divider()
            PageNavigationView(noteID: noteID, currentPageIndex: $currentPageIndex)
        }
    }
}

// MARK: - DrawingToolbarView

struct DrawingToolbarView: View {
    @Binding var selectedTool: DrawingTool
    @Binding var selectedColor: DrawingColor
    @Binding var selectedThickness: DrawingThickness

    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 4) {
                ToolToggleButton(icon: "pencil.tip", label: "ペン", isSelected: selectedTool == .pen) {
                    selectedTool = .pen
                }
                ToolToggleButton(icon: "eraser.fill", label: "消しゴム", isSelected: selectedTool == .eraser) {
                    selectedTool = .eraser
                }
            }
            Divider().frame(height: 32)
            HStack(spacing: 6) {
                ForEach(DrawingThickness.allCases, id: \.self) { t in
                    Button { selectedThickness = t } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedThickness == t ? Color.accentColor.opacity(0.15) : Color.clear)
                                .frame(width: 44, height: 44)
                            Circle().fill(Color.primary)
                                .frame(width: t.dotSize, height: t.dotSize)
                        }
                    }
                    .accessibilityLabel(t.label)
                }
            }
            Divider().frame(height: 32)
            HStack(spacing: 8) {
                ForEach(DrawingColor.allCases, id: \.self) { dc in
                    Button { selectedColor = dc; selectedTool = .pen } label: {
                        ZStack {
                            Circle().fill(dc.color).frame(width: 28, height: 28)
                                .shadow(color: dc.color.opacity(0.4), radius: 2, x: 0, y: 1)
                            if selectedTool == .pen && selectedColor == dc {
                                Circle().stroke(Color.primary.opacity(0.8), lineWidth: 2.5)
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel(dc.name)
                }
            }
        }
    }
}

private struct ToolToggleButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 18, weight: .regular))
                Text(label).font(.system(size: 10))
            }
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .frame(width: 56, height: 44)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear))
        }
    }
}

// MARK: - PageNavigationView

struct PageNavigationView: View {
    @EnvironmentObject private var noteStore: NoteStore
    let noteID: UUID
    @Binding var currentPageIndex: Int

    var body: some View {
        if let note = noteStore.notes.first(where: { $0.id == noteID }) {
            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        currentPageIndex = max(0, currentPageIndex - 1)
                    }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 60).contentShape(Rectangle())
                }
                .disabled(currentPageIndex == 0)
                .foregroundStyle(currentPageIndex == 0 ? .tertiary : .primary)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.pages.indices, id: \.self) { index in
                                PageThumbnailButton(pageNumber: index + 1,
                                                   isSelected: currentPageIndex == index)
                                    .id(index)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            currentPageIndex = index
                                        }
                                    }
                                    .contextMenu { pageContextMenu(index: index, note: note) }
                            }
                            addPageButton(note: note)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 8)
                    }
                    .onChange(of: currentPageIndex) { _, i in
                        withAnimation { proxy.scrollTo(i, anchor: .center) }
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        currentPageIndex = min(note.pages.count - 1, currentPageIndex + 1)
                    }
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 60).contentShape(Rectangle())
                }
                .disabled(currentPageIndex == note.pages.count - 1)
                .foregroundStyle(currentPageIndex == note.pages.count - 1 ? .tertiary : .primary)

                Text("\(currentPageIndex + 1) / \(note.pages.count)")
                    .font(.caption).foregroundStyle(.secondary)
                    .monospacedDigit().frame(minWidth: 50).padding(.trailing, 8)
            }
            .frame(height: 76)
            .background(.regularMaterial)
        }
    }

    @ViewBuilder
    private func pageContextMenu(index: Int, note: Note) -> some View {
        Button {
            noteStore.addPage(to: noteID, after: index)
            currentPageIndex = index + 1
        } label: { Label("この後にページを追加", systemImage: "plus.rectangle.on.rectangle") }

        if index > 0 {
            Button {
                noteStore.addPage(to: noteID, after: index - 1)
                currentPageIndex = index
            } label: { Label("この前にページを追加", systemImage: "rectangle.on.rectangle") }
        }

        Divider()

        if note.pages.count > 1 {
            Button(role: .destructive) {
                let isCurrent = currentPageIndex == index
                noteStore.deletePage(at: index, in: noteID)
                if isCurrent { currentPageIndex = max(0, index - 1) }
                else if currentPageIndex > index { currentPageIndex -= 1 }
            } label: { Label("このページを削除", systemImage: "trash") }
        }
    }

    @ViewBuilder
    private func addPageButton(note: Note) -> some View {
        Button {
            noteStore.addPage(to: noteID)
            if let updated = noteStore.notes.first(where: { $0.id == noteID }) {
                currentPageIndex = updated.pages.count - 1
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .frame(width: 38, height: 50)
                    Image(systemName: "plus").font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Text("追加").font(.system(size: 9)).foregroundStyle(.secondary)
            }
        }
    }
}

private struct PageThumbnailButton: View {
    let pageNumber: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(uiColor: .systemGray6))
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? Color.accentColor : Color(uiColor: .systemGray4),
                            lineWidth: isSelected ? 2 : 0.5)
                Text("\(pageNumber)")
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .frame(width: 38, height: 50)
            Text("p.\(pageNumber)").font(.system(size: 9))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
    }
}

// MARK: - CanvasView

struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: DrawingTool
    var color: DrawingColor
    var thickness: DrawingThickness

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = .white
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.alwaysBounceVertical = false
        canvas.isScrollEnabled = false
        applyTool(to: canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if !context.coordinator.isUpdatingFromDelegate && uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        applyTool(to: uiView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func applyTool(to canvas: PKCanvasView) {
        switch tool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: color.uiColor, width: thickness.penWidth)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap, width: thickness.eraserWidth)
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var isUpdatingFromDelegate = false
        init(_ parent: CanvasView) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromDelegate = true
            parent.drawing = canvasView.drawing
            isUpdatingFromDelegate = false
        }
    }
}
