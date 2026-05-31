import AppKit

final class StickyNoteWindow: NSWindow {

    private let trafficLightLeft: CGFloat = 16
    private let trafficLightTopMargin: CGFloat = 16
    private var trafficLightsInitialized = false

    // Always report as key/main so the glass material never switches to its inactive appearance.
    override var isKeyWindow: Bool { true }
    override var isMainWindow: Bool { true }

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

        // Disable system drawing on all three, replace with white circle layers.
        for btn in [close, minimize, zoom] {
            btn.isBordered = false
            btn.wantsLayer = true
            btn.layer?.backgroundColor = NSColor(white: 1, alpha: 0.25).cgColor
            btn.layer?.cornerRadius = bh / 2
        }

        // All three start hidden; NoteView's hover drives visibility.
        if !trafficLightsInitialized {
            for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                guard let btn = standardWindowButton(type) else { continue }
                btn.wantsLayer = true
                let blurFilter = CIFilter(name: "CIGaussianBlur")!
                blurFilter.name = "blur"
                blurFilter.setValue(0, forKey: kCIInputRadiusKey)
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                btn.layer?.opacity = 0
                btn.layer?.filters = [blurFilter]
                CATransaction.commit()
            }
            trafficLightsInitialized = true
        }
    }

    func updateCloseButtonForActiveState() {
        guard let layer = standardWindowButton(.closeButton)?.layer else { return }
        let toOpacity: Float = NSApp.isActive ? 1.0 : 0.5
        guard abs(layer.opacity - toOpacity) > 0.01 else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = toOpacity
        CATransaction.commit()
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = NSApp.isActive ? 0.5 : 1.0
        anim.toValue = toOpacity
        anim.duration = 0.2
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: "activeStateOpacity")
    }

    func setTrafficLightsVisible(_ visible: Bool) {
        let now = CACurrentMediaTime()
        let fromBlur: CGFloat = visible ? 8 : 0
        let toBlur: CGFloat   = visible ? 0 : 4
        let duration: Double  = visible ? 0.22 : 0.15

        // Close is full opacity only when the app is active; matches the others when in background.
        let visibleOpacity: [NSWindow.ButtonType: Float] = [
            .closeButton: NSApp.isActive ? 1.0 : 0.5,
            .miniaturizeButton: 0.5,
            .zoomButton: 0.5
        ]

        for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            guard let layer = standardWindowButton(type)?.layer else { continue }
            layer.removeAllAnimations()

            let peaked = visibleOpacity[type] ?? 1
            let toOpacity: Float   = visible ? peaked : 0
            let fromOpacity: Float = visible ? 0      : peaked

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.opacity = toOpacity
            (layer.filters?.first as? CIFilter)?.setValue(toBlur, forKey: kCIInputRadiusKey)
            CATransaction.commit()

            let group = CAAnimationGroup()
            group.duration = duration
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false
            group.beginTime = now

            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = fromOpacity; opacity.toValue = toOpacity

            let blur = CABasicAnimation(keyPath: "filters.blur.inputRadius")
            blur.fromValue = fromBlur; blur.toValue = toBlur

            group.animations = [opacity, blur]
            layer.add(group, forKey: "reveal")
        }
    }
}
