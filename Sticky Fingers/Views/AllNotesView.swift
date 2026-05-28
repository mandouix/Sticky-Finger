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
    var autoFocusSearch: Bool = false

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

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
                    .focused($searchFocused)
            }
            .padding(.horizontal, 10)
            .frame(height: allNotesSearchBarHeight)
            .background(Color.primary.opacity(0.06), in: Capsule())
            .glassEffect(.regular, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5))

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
            if autoFocusSearch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    searchFocused = true
                }
            }
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
    @State private var isTrashHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.document")
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
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                let wasSource = note.id == sourceNoteID
                let sourceFrame = wasSource ? WindowManager.shared.frame(for: sourceNoteID) : nil
                store.delete(id: note.id)
                WindowManager.shared.close(noteID: note.id)
                if wasSource {
                    let newNote = NoteStore.shared.add()
                    WindowManager.shared.open(newNote, at: sourceFrame)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(isTrashHovered ? Color.red : Color.secondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.15)) { isTrashHovered = hover }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: allNotesRowHeight)
        .background(isHovered ? Color.primary.opacity(0.07) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { isHovered = h } }
        .onTapGesture {
            WindowManager.shared.selectNote(note.id, replacing: sourceNoteID)
        }
    }
}
