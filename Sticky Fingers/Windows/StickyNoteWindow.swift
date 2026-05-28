import AppKit

final class StickyNoteWindow: NSWindow {

    private let trafficLightLeft: CGFloat = 16
    private let trafficLightTopMargin: CGFloat = 16
    private var trafficLightsInitialized = false

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        var rect = super.constrainFrameRect(frameRect, to: screen)
        let top = rect.maxY
        rect.size.width  = max(320, rect.size.width)
        rect.size.height = max(180, rect.size.height)
        rect.origin.y    = top - rect.size.height  // keep top edge fixed when height grows
        return rect
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        positionTrafficLights()
    }

    private func positionTrafficLights() {
        guard let close = standardWindowButton(.closeButton),
              let minimize = standardWindowButton(.miniaturizeButton),
              let zoom = standardWindowButton(.zoomButton),
              let container = close.superview else { return }

        // Miniaturize and zoom are visible but non-functional.
        minimize.isEnabled = false
        zoom.isEnabled = false

        let bh = close.frame.height
        let containerH = container.frame.height
        let originY = containerH - trafficLightTopMargin - bh
        let bw = close.frame.width
        let spacing = bw + 8  // 8pt gap between each button

        close.frame    = NSRect(x: trafficLightLeft,               y: originY, width: bw, height: bh)
        minimize.frame = NSRect(x: trafficLightLeft + spacing,     y: originY, width: bw, height: bh)
        zoom.frame     = NSRect(x: trafficLightLeft + spacing * 2, y: originY, width: bw, height: bh)

        // All three start hidden; NoteView's hover drives visibility.
        if !trafficLightsInitialized {
            close.alphaValue = 0
            minimize.alphaValue = 0
            zoom.alphaValue = 0
            trafficLightsInitialized = true
        }
    }

    func setTrafficLightsVisible(_ visible: Bool) {
        let target: CGFloat = visible ? 1 : 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            standardWindowButton(.closeButton)?.animator().alphaValue = target
            standardWindowButton(.miniaturizeButton)?.animator().alphaValue = target
            standardWindowButton(.zoomButton)?.animator().alphaValue = target
        }
    }
}
