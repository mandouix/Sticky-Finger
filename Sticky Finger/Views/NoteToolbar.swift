import SwiftUI
import AppKit

struct NoteToolbar: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore
    @ObservedObject var bridge: EditorBridge
    weak var windowController: NoteWindowController?

    var body: some View {
        HStack(spacing: 8) {
            ToolbarCircleButton(help: bridge.isPinned ? "Unpin" : "Pin above all windows") {
                windowController?.togglePin()
            } label: {
                ZStack {
                    Image(systemName: "pin")
                        .opacity(bridge.isPinned ? 0 : 1)
                        .scaleEffect(bridge.isPinned ? 0.25 : 1)
                        .blur(radius: bridge.isPinned ? 4 : 0)
                    Image(systemName: "pin.fill")
                        .opacity(bridge.isPinned ? 1 : 0)
                        .scaleEffect(bridge.isPinned ? 1 : 0.25)
                        .blur(radius: bridge.isPinned ? 0 : 4)
                }
                .animation(.easeInOut(duration: 0.2), value: bridge.isPinned)
            }

            HStack(spacing: 0) {
                CapsuleToolbarButton(icon: "doc.on.doc", help: "All notes") {
                    WindowManager.shared.openAllNotes(sourceNoteID: noteID)
                }

                Rectangle()
                    .fill(Color.primary.opacity(0.10))
                    .frame(width: 0.5, height: 16)

                CapsuleToolbarButton(icon: "plus", help: "New note") {
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
                        WindowManager.shared.open(newNote, at: NSRect(
                            x: max(screenFrame.minX, x), y: currentFrame.origin.y,
                            width: defaultSize.width, height: defaultSize.height))
                    } else {
                        WindowManager.shared.open(newNote)
                    }
                }
            }
            .glassEffect(.regular, in: Capsule())
        }
    }
}

private struct CapsuleToolbarButton: View {
    let icon: String
    let help: String
    let action: () -> Void

    @State private var isHovered = false
    @GestureState private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(isHovered ? 0.10 : 0)).frame(width: 28, height: 28))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in state = true }
        )
        .onHover { isHovered = $0 }
        .pointerCursor()
        .help(help)
    }
}

private struct ToolbarCircleButton<Label: View>: View {
    let help: String
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isHovered = false
    @GestureState private var isPressed = false

    var body: some View {
        label()
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
            .contentShape(Circle())
            .glassEffect(.regular, in: Circle())
            .overlay(Circle().fill(Color.white.opacity(isHovered ? 0.10 : 0)).frame(width: 28, height: 28))
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture { action() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
            )
            .onHover { isHovered = $0 }
            .pointerCursor()
            .help(help)
    }
}
