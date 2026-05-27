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

            HStack(spacing: 0) {
                Button {
                    WindowManager.shared.openAllNotes(sourceNoteID: noteID)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .help("All notes")

                Rectangle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 0.5, height: 16)

                Button {
                    let newNote = store.add()
                    if let currentFrame = windowController?.window?.frame {
                        let gap: CGFloat = 12
                        let screenFrame = windowController?.window?.screen?.visibleFrame
                            ?? NSScreen.main?.visibleFrame
                            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                        var x = currentFrame.maxX + gap
                        if x + currentFrame.width > screenFrame.maxX {
                            x = currentFrame.minX - gap - currentFrame.width
                        }
                        x = max(screenFrame.minX, x)
                        let newFrame = NSRect(x: x, y: currentFrame.origin.y,
                                             width: currentFrame.width, height: currentFrame.height)
                        WindowManager.shared.open(newNote, at: newFrame)
                    } else {
                        WindowManager.shared.open(newNote)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .help("New note")
            }
            .glassEffect(.regular, in: Capsule())
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
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: Circle())
        .pointerCursor()
        .help(help)
    }
}
