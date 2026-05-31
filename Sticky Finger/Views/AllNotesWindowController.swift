import AppKit
import SwiftUI

// Panel subclass that allows becoming key so the search TextField receives keyboard input.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AllNotesWindowController: NSWindowController, NSWindowDelegate {

    var sourceNoteID: UUID = UUID()
    private let store: NoteStore
    private var clickOutsideMonitor: Any?   // global — catches clicks in other apps
    private var clickLocalMonitor: Any?     // local  — catches clicks in this app (e.g. note window)

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

    private var pendingSearchFocus = false

    func showWithSearchFocused() {
        if window?.isVisible == true {
            window?.close()
            return
        }
        pendingSearchFocus = true
        showWindow(nil)
    }

    private func updateContent() {
        let focus = pendingSearchFocus
        pendingSearchFocus = false
        var view = AllNotesView(store: store, sourceNoteID: sourceNoteID, cornerRadius: 24, autoFocusSearch: focus)
        view.onHeightChange = { [weak self] height in
            DispatchQueue.main.async { self?.resizePanel(toHeight: height) }
        }
        let hostingView = NSHostingView(rootView: view)
        window?.contentView = hostingView

        if let frameView = hostingView.superview {
            frameView.wantsLayer = true
            frameView.layer?.cornerRadius = 24
            frameView.layer?.cornerCurve = .continuous
            frameView.layer?.masksToBounds = true
        }
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
        let handler: (NSEvent) -> Void = { [weak self] _ in
            guard let self, let win = self.window, win.isVisible else { return }
            if !win.frame.contains(NSEvent.mouseLocation) {
                DispatchQueue.main.async { win.close() }
            }
        }
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown], handler: handler)
        clickLocalMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                handler(event)
                return event
            }
    }

    private func stopMonitoringClickOutside() {
        [clickOutsideMonitor, clickLocalMonitor].forEach {
            if let m = $0 { NSEvent.removeMonitor(m) }
        }
        clickOutsideMonitor = nil
        clickLocalMonitor = nil
    }
}
