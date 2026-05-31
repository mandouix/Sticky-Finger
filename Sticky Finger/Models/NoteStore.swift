import Foundation
import Combine

@MainActor
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    @Published private(set) var notes: [Note] = []

    private let saveURL: URL
    private var saveTask: Task<Void, Never>?

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Sticky Finger", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("notes.json")
        Self.migrateLegacyStoreIfNeeded(into: saveURL, appSupport: appSupport)
        load()
    }

    /// Move notes saved by older versions (which used a "New Sticky" folder) into
    /// the current location, so existing notes survive the rename.
    private static func migrateLegacyStoreIfNeeded(into saveURL: URL, appSupport: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: saveURL.path) else { return }
        let legacy = appSupport
            .appendingPathComponent("New Sticky", isDirectory: true)
            .appendingPathComponent("notes.json")
        guard fm.fileExists(atPath: legacy.path) else { return }
        try? fm.copyItem(at: legacy, to: saveURL)
    }

    func add() -> Note {
        let note = Note()
        notes.insert(note, at: 0)
        scheduleSave()
        return note
    }

    func update(id: UUID, content: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].content = content
        notes[index].updatedAt = Date()
        scheduleSave()
    }

    func update(id: UUID, color: NoteColor) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].noteColor = color
        scheduleSave()
    }

    func delete(id: UUID) {
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    func note(id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Note].self, from: data) else {
            return
        }
        notes = decoded
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.persist()
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
