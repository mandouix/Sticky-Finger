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
            contentRect: NSRect(x: 0, y: 0, width: 272, height: 214),
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
        let view = AllNotesView(store: store, sourceNoteID: sourceNoteID, cornerRadius: radius)
        window?.contentView = NSHostingView(rootView: view)
    }

    override func showWindow(_ sender: Any?) {
        updateContent()
        super.showWindow(sender)
        // Make the panel key so the search field can receive keyboard input.
        window?.makeKeyAndOrderFront(nil)
        startMonitoringClickOutside()
    }

    func windowWillClose(_ notification: Notification) {
        stopMonitoringClickOutside()
        WindowManager.shared.allNotesController = nil
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
