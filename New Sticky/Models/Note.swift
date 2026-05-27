import Foundation

struct Note: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var content: String = ""
    var noteColor: NoteColor = .default
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var title: String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            ?? ""
        // Strip leading markdown heading markers for display
        let stripped = firstLine
            .replacingOccurrences(of: "^#{1,6}\\s+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        return stripped.isEmpty ? "New Note" : stripped
    }

    var characterCount: Int {
        content.count
    }
}
