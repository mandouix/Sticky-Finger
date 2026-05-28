import AppKit
import SwiftUI
import Combine

final class NoteWindowController: NSWindowController, NSWindowDelegate {

    let noteID: UUID
    private let store: NoteStore
    let bridge = EditorBridge()

    private let headerHeight: CGFloat = 56
    private let footerHeight: CGFloat = 52
    private let webLeft: CGFloat = 16
    private let barH: CGFloat = 40     // panel height (36pt bar + 4pt breathing room)
    private let barHalfW: CGFloat = 80 // clamp margin

    private var formatPanel: NSPanel?
    private var stateCancellable: AnyCancellable?
    private var hoverTimer: Timer?
    private var appActivationObservers: [NSObjectProtocol] = []

    private var isResizingProgrammatically = false
    private var isHeightManuallyReduced = false
    private var currentEditorHeight: CGFloat = 56

    init(note: Note, store: NoteStore) {
        self.noteID = note.id
        self.store = store

        let window = StickyNoteWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
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
        window.minSize = NSSize(width: 320, height: 180)
        window.center()

        super.init(window: window)
        window.delegate = self

        let view = NoteView(noteID: note.id, store: store, windowController: self, bridge: bridge)
        window.contentView = NSHostingView(rootView: view)

        // Clip the NSThemeFrame to our glass corner radius so the system border
        // and the glass edge share the same geometry — otherwise two borders appear.
        if let frameView = window.contentView?.superview {
            frameView.wantsLayer = true
            frameView.layer?.cornerRadius = 24
            frameView.layer?.cornerCurve = .continuous
            frameView.layer?.masksToBounds = true
        }

        setupFormatPanel(in: window)
        bridge.isPinned = window.isPinned
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Format bar panel

    private func setupFormatPanel(in window: NSWindow) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: barHalfW * 2, height: barH),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: FormatBar(bridge: bridge))

        if let frameView = panel.contentView?.superview {
            frameView.wantsLayer = true
            frameView.layer?.cornerRadius = barH / 2   // matches Capsule shape
            frameView.layer?.cornerCurve = .continuous
            frameView.layer?.masksToBounds = true
        }

        window.addChildWindow(panel, ordered: .above)
        formatPanel = panel

        // Poll mouse location so hover stays true over child panel and titlebar buttons
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let win = self.window else { return }
            let mouse = NSEvent.mouseLocation
            let hovered = win.frame.contains(mouse)
                       || (self.formatPanel?.frame.contains(mouse) == true)
            if self.bridge.isWindowHovered != hovered {
                self.bridge.isWindowHovered = hovered
                self.setTrafficLightsVisible(hovered)
                if hovered { WindowManager.shared.activeNoteID = self.noteID }
            }
        }

        stateCancellable = bridge.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateFormatPanel(state: state)
            }

        let nc = NotificationCenter.default
        appActivationObservers = [
            nc.addObserver(forName: NSApplication.didResignActiveNotification,
                           object: nil, queue: .main) { [weak self] _ in
                self?.bridge.blurEditor()
                if self?.bridge.isWindowHovered == true {
                    (self?.window as? StickyNoteWindow)?.updateCloseButtonForActiveState()
                }
            },
            nc.addObserver(forName: NSApplication.didBecomeActiveNotification,
                           object: nil, queue: .main) { [weak self] _ in
                guard let self, let win = self.window else { return }
                // Make the web view first responder so the cursor is live, then JS-focus the editor.
                if let webView = bridge.webView {
                    win.makeFirstResponder(webView)
                }
                bridge.focusEditor()
                if bridge.isWindowHovered {
                    (win as? StickyNoteWindow)?.updateCloseButtonForActiveState()
                }
            }
        ]
    }

    private func updateFormatPanel(state: EditorBridge.FormatState) {
        guard let panel = formatPanel, let window = window else { return }

        guard state.visible else {
            panel.orderOut(nil)
            return
        }

        let r = state.selectionRect
        let windowFrame = window.frame
        let windowH = windowFrame.height

        let selCenterX = webLeft + r.midX
        let selTopY    = headerHeight + r.minY
        let selBotY    = headerHeight + r.maxY

        // Show above selection; fall back below when near top
        let centerYFromTop: CGFloat = selTopY - 8 - barH > 4
            ? selTopY - 8 - barH / 2
            : selBotY + 8 + barH / 2

        // Clamp horizontal position
        let clampedX = max(barHalfW, min(windowFrame.width - barHalfW, selCenterX))

        // Convert window-local (top-left) → screen (bottom-left)
        let screenX = windowFrame.minX + clampedX - barHalfW
        let screenY = windowFrame.minY + (windowH - centerYFromTop) - barH / 2

        panel.setFrame(NSRect(x: screenX, y: screenY, width: barHalfW * 2, height: barH),
                       display: true)

        if !panel.isVisible {
            panel.orderFront(nil)
        }
    }

    // MARK: - Public

    func togglePin() {
        bridge.isPinned = window?.togglePin() ?? false
    }

    func setTrafficLightsVisible(_ visible: Bool) {
        (window as? StickyNoteWindow)?.setTrafficLightsVisible(visible)
    }

    func resizeToFit(editorHeight: CGFloat) {
        currentEditorHeight = editorHeight
        guard let window else { return }

        let desired = headerHeight + editorHeight + footerHeight
        let maxH = (window.screen ?? NSScreen.main).map { $0.visibleFrame.height } ?? 900
        let newH = max(window.minSize.height, min(maxH, desired))

        if isHeightManuallyReduced {
            // Content shrank enough to fit in the manual window — snap back to content-hugged
            if newH <= window.frame.height + 2 {
                isHeightManuallyReduced = false
            } else {
                return
            }
        }

        guard abs(window.frame.height - newH) > 1 else { return }

        isResizingProgrammatically = true
        var frame = window.frame
        frame.origin.y += frame.height - newH
        frame.size.height = newH
        window.setFrame(frame, display: true, animate: false)
        isResizingProgrammatically = false
    }

    // MARK: - NSWindowDelegate

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        NSSize(width: max(320, frameSize.width), height: max(180, frameSize.height))
    }

    func windowDidResize(_ notification: Notification) {
        guard !isResizingProgrammatically, let window else { return }
        let desired = headerHeight + currentEditorHeight + footerHeight
        isHeightManuallyReduced = window.frame.height < desired - 2
    }

    func windowWillClose(_ notification: Notification) {
        hoverTimer?.invalidate()
        formatPanel?.close()
        appActivationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        appActivationObservers = []
        let note = store.note(id: noteID)
        if note?.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            store.delete(id: noteID)
        }
        WindowManager.shared.didClose(noteID: noteID)
    }
}
