import SwiftUI
import AppKit

struct NoteToolbar: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore
    weak var windowController: NoteWindowController?

    @State private var isPinned = false

    var body: some View {
        HStack(spacing: 8) {
            ToolbarCircleButton(help: isPinned ? "Unpin" : "Pin above all windows") {
                isPinned = windowController?.window?.togglePin() ?? false
            } label: {
                ZStack {
                    Image(systemName: "pin")
                        .opacity(isPinned ? 0 : 1)
                        .scaleEffect(isPinned ? 0.25 : 1)
                        .blur(radius: isPinned ? 4 : 0)
                    Image(systemName: "pin.fill")
                        .opacity(isPinned ? 1 : 0)
                        .scaleEffect(isPinned ? 1 : 0.25)
                        .blur(radius: isPinned ? 0 : 4)
                }
                .animation(.easeInOut(duration: 0.2), value: isPinned)
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
                    let defaultSize = NSSize(width: 320, height: 180)
                    if let currentFrame = windowController?.window?.frame {
                        let gap: CGFloat = 12
                        let screenFrame = windowController?.window?.screen?.visibleFrame
                            ?? NSScreen.main?.visibleFrame
                            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                        var x = currentFrame.maxX + gap
                        if x + defaultSize.width > screenFrame.maxX {
                            x = currentFrame.minX - gap - defaultSize.width
                        }
                        x = max(screenFrame.minX, x)
                        let newFrame = NSRect(x: x, y: currentFrame.origin.y,
                                             width: defaultSize.width, height: defaultSize.height)
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

private struct ToolbarCircleButton<Label: View>: View {
    let help: String
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @GestureState private var isPressed = false

    var body: some View {
        Button(action: action) {
            label()
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: Circle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in state = true }
        )
        .pointerCursor()
        .help(help)
    }
}
