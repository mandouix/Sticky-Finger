import AppKit
import SwiftUI

extension View {
    func pointerCursor() -> some View {
        onHover { inside in
            if inside { NSCursor.pointingHand.push() }
            else { NSCursor.pop() }
        }
    }
}

extension NSWindow {
    @discardableResult
    func togglePin() -> Bool {
        let nowPinned = level != .floating
        level = nowPinned ? .floating : .normal
        return nowPinned
    }

    var isPinned: Bool { level == .floating }
}
