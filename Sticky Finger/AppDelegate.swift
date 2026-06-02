import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupKeyboardShortcuts()
        WindowManager.shared.openAllExistingNotes()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Called when the app is relaunched while already running (e.g. from Launchpad or the
    /// Dock). When no note windows are open, bring back the most recently edited note so the
    /// user always lands somewhere instead of nothing happening.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            WindowManager.shared.reopenMostRecentNote()
        }
        return true
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            let image = NSImage(named: "MenuBarIcon")
            image?.isTemplate = true   // tint to match the menu bar (adapts to light/dark)
            image?.size = NSSize(width: 16, height: 16)
            button.image = image
            button.image?.accessibilityDescription = "Sticky Finger"
        }

        let menu = NSMenu()

        let newNoteItem = NSMenuItem(title: "New Note", action: #selector(newNote), keyEquivalent: "n")
        newNoteItem.target = self
        menu.addItem(newNoteItem)

        let allNotesItem = NSMenuItem(title: "All Notes", action: #selector(showAllNotes), keyEquivalent: "a")
        allNotesItem.target = self
        menu.addItem(allNotesItem)

        menu.addItem(.separator())

        let feedbackItem = NSMenuItem(title: "Send Feedback\u{2026}", action: #selector(sendFeedback), keyEquivalent: "")
        feedbackItem.target = self
        menu.addItem(feedbackItem)

        menu.addItem(.separator())

        menu.addItem(withTitle: "Quit Sticky Finger", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.modifierFlags.intersection([.command, .shift, .option, .control]) == .command
            else { return event }
            switch event.charactersIgnoringModifiers {
            case "n": self.newNote();              return nil
            case "f": self.openAllNotesSearch();   return nil
            case "p": self.togglePinActive();      return nil
            case "q": self.closeActiveNote();      return nil
            default:  return event
            }
        }
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

    private func openAllNotesSearch() {
        NSApp.activate(ignoringOtherApps: true)
        let sourceID = WindowManager.shared.activeNoteID
            ?? NoteStore.shared.notes.first?.id
            ?? NoteStore.shared.add().id
        WindowManager.shared.openAllNotesWithSearch(sourceNoteID: sourceID)
    }

    private func togglePinActive() {
        guard let id = WindowManager.shared.activeNoteID,
              let ctrl = WindowManager.shared.controller(for: id) else { return }
        ctrl.togglePin()
    }

    private func closeActiveNote() {
        guard let id = WindowManager.shared.activeNoteID else { return }
        WindowManager.shared.close(noteID: id)
    }

    @objc private func sendFeedback() {
        let to = "mandar.chaudhari98@gmail.com"
        let subject = "Sticky Finger Feedback"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(to)?subject=\(subject)") {
            NSWorkspace.shared.open(url)
        }
    }
}
