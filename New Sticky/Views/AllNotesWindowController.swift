import AppKit
import SwiftUI

// Panel subclass that allows becoming key so the search TextField receives keyboard input.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AllNotesWindowController: NSWindowController, NSWindowDelegate {

    var sourceNoteID: UUID = UUID()
    private let store: NoteStore
    private var clickOutsideMonitor: Any?

    init(store: NoteStore) {
        self.store = store

        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: allNotesPanelWidth, height: allNotesPanelMaxHeight),
            styleMask: [.nonactivatingPanel, .borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.level = .floating

        super.init(window: panel)
        panel.delegate = self
        updateContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func updateContent() {
        let radius = WindowManager.shared.noteWindowCornerRadius()
        var view = AllNotesView(store: store, sourceNoteID: sourceNoteID, cornerRadius: radius)
        view.onHeightChange = { [weak self] height in
            DispatchQueue.main.async { self?.resizePanel(toHeight: height) }
        }
        window?.contentView = NSHostingView(rootView: view)
    }

    override func showWindow(_ sender: Any?) {
        updateContent()
        // Size the panel to fit the current note count before it appears.
        let h = allNotesPanelHeight(noteCount: store.notes.count)
        window?.setContentSize(NSSize(width: allNotesPanelWidth, height: h))
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        startMonitoringClickOutside()
    }

    func windowWillClose(_ notification: Notification) {
        stopMonitoringClickOutside()
        WindowManager.shared.allNotesController = nil
    }

    // MARK: - Panel resize

    private func resizePanel(toHeight height: CGFloat) {
        guard let window else { return }
        let newH = min(height, allNotesPanelMaxHeight)
        guard abs(window.frame.height - newH) > 1 else { return }
        var frame = window.frame
        frame.origin.y += frame.height - newH   // keep top edge fixed
        frame.size.height = newH
        window.setFrame(frame, display: true, animate: false)
    }

    // MARK: - Click-outside-to-close

    private func startMonitoringClickOutside() {
        stopMonitoringClickOutside()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let win = self.window, win.isVisible else { return }
            let mouse = NSEvent.mouseLocation
            if !win.frame.contains(mouse) {
                DispatchQueue.main.async { win.close() }
            }
        }
    }

    private func stopMonitoringClickOutside() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
}
