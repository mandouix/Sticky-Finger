import SwiftUI

// Shared layout constants — used by both AllNotesView and AllNotesWindowController.
let allNotesPanelWidth: CGFloat = 280
let allNotesPanelMaxHeight: CGFloat = 240
let allNotesRowHeight: CGFloat = 52
let allNotesSearchBarHeight: CGFloat = 36
let allNotesPanelPadding: CGFloat = 8
let allNotesPanelSpacing: CGFloat = 4

/// Computes the panel height for a given number of visible note rows.
func allNotesPanelHeight(noteCount: Int) -> CGFloat {
    let maxListH = allNotesPanelMaxHeight - allNotesPanelPadding * 2
                   - allNotesSearchBarHeight - allNotesPanelSpacing
    let listH: CGFloat = noteCount > 0
        ? allNotesPanelSpacing + min(CGFloat(noteCount) * allNotesRowHeight, maxListH)
        : 0
    return allNotesPanelPadding * 2 + allNotesSearchBarHeight + listH
}

struct AllNotesView: View {
    @ObservedObject var store: NoteStore
    let sourceNoteID: UUID
    var cornerRadius: CGFloat = 10
    var onHeightChange: ((CGFloat) -> Void)? = nil

    @State private var searchText = ""

    private var filtered: [Note] {
        if searchText.isEmpty { return store.notes }
        return store.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var listHeight: CGFloat {
        let maxListH = allNotesPanelMaxHeight - allNotesPanelPadding * 2
                       - allNotesSearchBarHeight - allNotesPanelSpacing
        return min(CGFloat(filtered.count) * allNotesRowHeight, maxListH)
    }

    var body: some View {
        VStack(spacing: allNotesPanelSpacing) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 10)
            .frame(height: allNotesSearchBarHeight)
            .glassEffect(.regular, in: Capsule())

            if !filtered.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { note in
                            NoteRow(note: note, sourceNoteID: sourceNoteID, store: store)
                        }
                    }
                }
                .frame(height: listHeight)
            }
        }
        .padding(allNotesPanelPadding)
        .frame(width: allNotesPanelWidth)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            onHeightChange?(allNotesPanelHeight(noteCount: filtered.count))
        }
        .onChange(of: filtered.count) { _, count in
            onHeightChange?(allNotesPanelHeight(noteCount: count))
        }
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
        .frame(height: allNotesRowHeight)
        .background(isHovered ? Color.primary.opacity(0.07) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            WindowManager.shared.selectNote(note.id, replacing: sourceNoteID)
        }
    }
}
