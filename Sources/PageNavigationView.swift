import SwiftUI

struct PageNavigationView: View {
    @Environment(NoteStore.self) private var noteStore
    let noteID: UUID
    @Binding var currentPageIndex: Int

    var body: some View {
        if let note = noteStore.notes.first(where: { $0.id == noteID }) {
            HStack(spacing: 0) {

                // Previous page
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        currentPageIndex = max(0, currentPageIndex - 1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 60)
                        .contentShape(Rectangle())
                }
                .disabled(currentPageIndex == 0)
                .foregroundStyle(currentPageIndex == 0 ? .tertiary : .primary)

                // Page thumbnails
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.pages.indices, id: \.self) { index in
                                PageThumbnailButton(
                                    pageNumber: index + 1,
                                    isSelected: currentPageIndex == index
                                )
                                .id(index)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        currentPageIndex = index
                                    }
                                }
                                .contextMenu {
                                    pageContextMenu(index: index, note: note)
                                }
                            }

                            // Add page button
                            addPageButton(note: note)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: currentPageIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                // Next page
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        currentPageIndex = min(note.pages.count - 1, currentPageIndex + 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 60)
                        .contentShape(Rectangle())
                }
                .disabled(currentPageIndex == note.pages.count - 1)
                .foregroundStyle(currentPageIndex == note.pages.count - 1 ? .tertiary : .primary)

                // Page counter label
                Text("\(currentPageIndex + 1) / \(note.pages.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 50)
                    .padding(.trailing, 8)
            }
            .frame(height: 76)
            .background(.regularMaterial)
        }
    }

    @ViewBuilder
    private func pageContextMenu(index: Int, note: Note) -> some View {
        Button {
            noteStore.addPage(to: noteID, after: index)
            // Navigate to the newly inserted page
            currentPageIndex = index + 1
        } label: {
            Label("この後にページを追加", systemImage: "plus.rectangle.on.rectangle")
        }

        if index > 0 {
            Button {
                noteStore.addPage(to: noteID, after: index - 1)
                currentPageIndex = index
            } label: {
                Label("この前にページを追加", systemImage: "rectangle.on.rectangle")
            }
        }

        Divider()

        if note.pages.count > 1 {
            Button(role: .destructive) {
                let isCurrentPage = currentPageIndex == index
                noteStore.deletePage(at: index, in: noteID)
                if isCurrentPage {
                    currentPageIndex = max(0, index - 1)
                } else if currentPageIndex > index {
                    currentPageIndex -= 1
                }
            } label: {
                Label("このページを削除", systemImage: "trash")
            }
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
                        .stroke(
                            Color.secondary.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5])
                        )
                        .frame(width: 38, height: 50)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text("追加")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - PageThumbnailButton

private struct PageThumbnailButton: View {
    let pageNumber: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.15)
                          : Color(uiColor: .systemGray6))

                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        isSelected ? Color.accentColor : Color(uiColor: .systemGray4),
                        lineWidth: isSelected ? 2 : 0.5
                    )

                Text("\(pageNumber)")
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .frame(width: 38, height: 50)

            Text("p.\(pageNumber)")
                .font(.system(size: 9))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
    }
}
