import AppKit

extension NSWindow {
    @discardableResult
    func togglePin() -> Bool {
        let nowPinned = level != .floating
        level = nowPinned ? .floating : .normal
        return nowPinned
    }

    var isPinned: Bool { level == .floating }
}
