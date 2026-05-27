import AppKit

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var controllers: [UUID: NoteWindowController] = [:]
    var allNotesController: AllNotesWindowController?

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
            // src.maxY is the top of the note window in screen coords (y=0 at bottom).
            // Subtract 120pt to get 120pt from the top, then subtract panel height for origin.y.
            let y = src.maxY - 80 - panelSize.height
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
        let notes = NoteStore.shared.notes
        if notes.isEmpty {
            let note = NoteStore.shared.add()
            open(note)
        } else {
            notes.prefix(1).forEach { open($0) }
        }
    }
}
