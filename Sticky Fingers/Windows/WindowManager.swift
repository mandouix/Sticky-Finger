import AppKit

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var controllers: [UUID: NoteWindowController] = [:]
    var allNotesController: AllNotesWindowController?
    var activeNoteID: UUID?

    private init() {}

    // MARK: - Note Windows

    func open(_ note: Note, at frame: NSRect? = nil) {
        if let existing = controllers[note.id] {
            if let frame { existing.window?.setFrame(frame, display: true) }
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        let controller = NoteWindowController(note: note, store: NoteStore.shared)
        controllers[note.id] = controller
        controller.showWindow(nil)
        if let frame { controller.window?.setFrame(frame, display: true) }
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func close(noteID: UUID) {
        controllers[noteID]?.window?.close()
        controllers.removeValue(forKey: noteID)
    }


    func frame(for noteID: UUID) -> NSRect? {
        controllers[noteID]?.window?.frame
    }

    func controller(for noteID: UUID) -> NoteWindowController? {
        controllers[noteID]
    }

    /// Returns the actual corner radius macOS is using for note windows.
    /// Reads it from the window frame view layer; falls back to 10 if unavailable.
    func noteWindowCornerRadius() -> CGFloat {
        guard let window = controllers.values.first?.window else { return 10 }
        let r = window.contentView?.superview?.layer?.cornerRadius ?? 0
        return r > 0 ? r : 10
    }

    func didClose(noteID: UUID) {
        controllers.removeValue(forKey: noteID)
    }

    func openAllNotesWithSearch(sourceNoteID: UUID) {
        if allNotesController == nil {
            allNotesController = AllNotesWindowController(store: NoteStore.shared)
        }
        guard let controller = allNotesController else { return }
        controller.sourceNoteID = sourceNoteID

        let panelSize = controller.window?.frame.size ?? NSSize(width: allNotesPanelWidth, height: 214)
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin: NSPoint
        if let src = frame(for: sourceNoteID) {
            let x = src.midX - panelSize.width / 2
            let y = src.midY - panelSize.height / 2
            origin = NSPoint(x: max(screenFrame.minX, x), y: max(screenFrame.minY, y))
        } else {
            origin = NSPoint(
                x: screenFrame.midX - panelSize.width / 2,
                y: screenFrame.midY - panelSize.height / 2
            )
        }
        controller.window?.setFrameOrigin(origin)
        controller.showWithSearchFocused()
    }

    func openAllNotes(sourceNoteID: UUID) {
        let store = NoteStore.shared
        if allNotesController == nil {
            allNotesController = AllNotesWindowController(store: store)
        }
        guard let controller = allNotesController else { return }
        controller.sourceNoteID = sourceNoteID

        // Overlap the source note window: horizontally centred on it, top 120pt below its top edge.
        let panelSize = controller.window?.frame.size ?? NSSize(width: 272, height: 214)
        let sourceFrame = frame(for: sourceNoteID)
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin: NSPoint
        if let src = sourceFrame {
            let x = src.midX - panelSize.width / 2
            let y = src.midY - panelSize.height / 2
            origin = NSPoint(x: x, y: max(screenFrame.minY, y))
        } else {
            origin = NSPoint(
                x: screenFrame.midX - panelSize.width / 2,
                y: screenFrame.midY - panelSize.height / 2
            )
        }
        controller.window?.setFrameOrigin(origin)

        if controller.window?.isVisible == true {
            controller.window?.close()
        } else {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
        }
    }

    // Called from AllNotesView when user selects a note
    func selectNote(_ selectedID: UUID, replacing sourceNoteID: UUID) {
        let sourceFrame = frame(for: sourceNoteID)
        allNotesController?.window?.close()
        close(noteID: sourceNoteID)

        guard let note = NoteStore.shared.note(id: selectedID) else { return }
        open(note, at: sourceFrame)
    }

    // MARK: - Open all existing notes on launch

    func openAllExistingNotes() {
        let store = NoteStore.shared
        if store.notes.isEmpty {
            let note = store.add()
            store.update(id: note.id, content: WindowManager.welcomeContent)
            open(store.note(id: note.id) ?? note)
        } else {
            store.notes.prefix(1).forEach { open($0) }
        }
    }

    private static let welcomeContent = """
# Welcome to Sticky Fingers

Your lightweight floating notes app for macOS. Notes float above all other windows so they're always in view.

## Shortcuts

⌘N — New note

⌘F — Search all notes

⌘P — Pin / unpin above all windows

⌘Q — Close note

## Tips

- Hover over a note to reveal the toolbar and color picker
- Select text to bring up the format bar
- Drag anywhere on the note to reposition it
- Click the color dot to change the note theme
"""
}
