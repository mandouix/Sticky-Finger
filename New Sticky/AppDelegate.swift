import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        WindowManager.shared.openAllExistingNotes()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "New Sticky")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "New Note", action: #selector(newNote), keyEquivalent: "n")
        menu.addItem(withTitle: "All Notes", action: #selector(showAllNotes), keyEquivalent: "a")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit New Sticky", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    @objc private func newNote() {
        let note = NoteStore.shared.add()
        WindowManager.shared.open(note)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAllNotes() {
        let notes = NoteStore.shared.notes
        guard let first = notes.first else {
            newNote()
            return
        }
        WindowManager.shared.open(first)
        NSApp.activate(ignoringOtherApps: true)
    }
}
