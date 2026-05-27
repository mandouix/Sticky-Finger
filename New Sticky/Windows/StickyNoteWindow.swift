import AppKit

// NSWindow subclass that repositions traffic lights to (16pt from left, 16pt from top).
final class StickyNoteWindow: NSWindow {

    private let trafficLightLeft: CGFloat = 16
    private let trafficLightTopMargin: CGFloat = 16

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        positionTrafficLights()
    }

    private func positionTrafficLights() {
        guard let close = standardWindowButton(.closeButton),
              let minimize = standardWindowButton(.miniaturizeButton),
              let zoom = standardWindowButton(.zoomButton),
              let container = close.superview else { return }

        let bh = close.frame.height          // button height (≈12pt)
        let containerH = container.frame.height
        // origin_y in AppKit coords (y=0 at bottom):
        // center should be trafficLightTopMargin+bh/2 from window top
        // → origin = containerH - trafficLightTopMargin - bh
        let originY = containerH - trafficLightTopMargin - bh

        let spacing: CGFloat = 20  // center-to-center
        let bw = close.frame.width

        close.frame    = NSRect(x: trafficLightLeft,                origin: originY, size: NSSize(width: bw, height: bh))
        minimize.frame = NSRect(x: trafficLightLeft + spacing,      origin: originY, size: NSSize(width: bw, height: bh))
        zoom.frame     = NSRect(x: trafficLightLeft + spacing * 2,  origin: originY, size: NSSize(width: bw, height: bh))
    }
}

private extension NSRect {
    init(x: CGFloat, origin y: CGFloat, size: NSSize) {
        self.init(x: x, y: y, width: size.width, height: size.height)
    }
}
