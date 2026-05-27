import AppKit
import SwiftUI

final class NoteWindowController: NSWindowController, NSWindowDelegate {

    let noteID: UUID
    private let store: NoteStore

    // header: HStack frame(32) + bottom-pad(8) = 40pt
    // footer: 30pt bottom padding added below TiptapEditor in NoteView
    private let headerHeight: CGFloat = 56
    private let footerHeight: CGFloat = 30

    init(note: Note, store: NoteStore) {
        self.noteID = note.id
        self.store = store

        let window = StickyNoteWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 180),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.minSize = NSSize(width: 240, height: 140)
        window.center()

        super.init(window: window)
        window.delegate = self

        let view = NoteView(noteID: note.id, store: store, windowController: self)
        window.contentView = NSHostingView(rootView: view)
    }

    required init?(coder: NSCoder) { fatalError() }

    func resizeToFit(editorHeight: CGFloat) {
        guard let window else { return }
        let screen = window.screen ?? NSScreen.main
        let maxH = screen.map { $0.visibleFrame.height } ?? 900

        let desired = headerHeight + editorHeight + footerHeight
        let newH = min(maxH, max(window.minSize.height, desired))

        guard abs(window.frame.height - newH) > 1 else { return }

        var frame = window.frame
        frame.origin.y += frame.height - newH
        frame.size.height = newH
        window.setFrame(frame, display: true, animate: false)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        let note = store.note(id: noteID)
        if note?.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            store.delete(id: noteID)
        }
        WindowManager.shared.didClose(noteID: noteID)
    }
}
