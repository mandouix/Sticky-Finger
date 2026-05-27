import SwiftUI

// Row height used to calculate fixed panel scroll area (3 rows visible)
private let rowHeight: CGFloat = 52

struct AllNotesView: View {
    @ObservedObject var store: NoteStore
    let sourceNoteID: UUID
    var cornerRadius: CGFloat = 10

    @State private var searchText = ""

    private var filtered: [Note] {
        if searchText.isEmpty { return store.notes }
        return store.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .glassEffect(.regular, in: Capsule())

            // Notes list — capped at 3 rows, scrollable beyond that
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { note in
                        NoteRow(note: note, sourceNoteID: sourceNoteID, store: store)
                    }
                }
            }
            .frame(height: rowHeight * 3)
        }
        .padding(8)
        .frame(width: 256)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct NoteRow: View {
    let note: Note
    let sourceNoteID: UUID
    let store: NoteStore

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(note.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(note.characterCount) characters")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.delete(id: note.id)
                WindowManager.shared.close(noteID: note.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(height: rowHeight)
        .background(isHovered ? Color.primary.opacity(0.07) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            WindowManager.shared.selectNote(note.id, replacing: sourceNoteID)
        }
    }
}
