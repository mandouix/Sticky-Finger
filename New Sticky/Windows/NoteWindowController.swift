import AppKit
import SwiftUI
import Combine

final class NoteWindowController: NSWindowController, NSWindowDelegate {

    let noteID: UUID
    private let store: NoteStore
    let bridge = EditorBridge()

    private let headerHeight: CGFloat = 56
    private let footerHeight: CGFloat = 34
    private let webLeft: CGFloat = 16
    private let barH: CGFloat = 40     // panel height (36pt bar + 4pt breathing room)
    private let barHalfW: CGFloat = 80 // clamp margin

    private var formatPanel: NSPanel?
    private var stateCancellable: AnyCancellable?
    private var hoverTimer: Timer?

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
        window.minSize = NSSize(width: 320, height: 1)
        window.center()

        super.init(window: window)
        window.delegate = self

        let view = NoteView(noteID: note.id, store: store, windowController: self, bridge: bridge)
        window.contentView = NSHostingView(rootView: view)

        setupFormatPanel(in: window)
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
            }
        }

        stateCancellable = bridge.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateFormatPanel(state: state)
            }
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

    func setTrafficLightsVisible(_ visible: Bool) {
        (window as? StickyNoteWindow)?.setTrafficLightsVisible(visible)
    }

    func resizeToFit(editorHeight: CGFloat) {
        guard let window else { return }
        let screen = window.screen ?? NSScreen.main
        let maxH = screen.map { $0.visibleFrame.height } ?? 900

        let desired = headerHeight + editorHeight + footerHeight
        let newH = min(maxH, desired)

        guard abs(window.frame.height - newH) > 1 else { return }

        var frame = window.frame
        frame.origin.y += frame.height - newH
        frame.size.height = newH
        window.setFrame(frame, display: true, animate: false)
    }

    // MARK: - NSWindowDelegate

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        NSSize(width: max(320, frameSize.width), height: frameSize.height)
    }

    func windowWillClose(_ notification: Notification) {
        hoverTimer?.invalidate()
        formatPanel?.close()
        let note = store.note(id: noteID)
        if note?.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            store.delete(id: noteID)
        }
        WindowManager.shared.didClose(noteID: noteID)
    }
}
