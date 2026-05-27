import SwiftUI
import AppKit

struct NoteToolbar: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore
    weak var windowController: NoteWindowController?

    @State private var isPinned = false

    var body: some View {
        HStack(spacing: 8) {
            ToolbarCircleButton(systemImage: isPinned ? "pin.fill" : "pin", help: isPinned ? "Unpin" : "Pin above all windows") {
                isPinned = windowController?.window?.togglePin() ?? false
            }

            ToolbarCircleButton(systemImage: "doc.on.doc", help: "All notes") {
                WindowManager.shared.openAllNotes(sourceNoteID: noteID)
            }

            ToolbarCircleButton(systemImage: "plus", help: "New note") {
                let newNote = store.add()
                let currentWindow = windowController?.window
                let currentFrame = currentWindow?.frame
                WindowManager.shared.open(newNote, at: currentFrame)
                currentWindow?.close()
            }
        }
        .onAppear {
            isPinned = windowController?.window?.isPinned ?? false
        }
    }
}

private struct ToolbarCircleButton: View {
    let systemImage: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: Circle())
        .help(help)
    }
}
