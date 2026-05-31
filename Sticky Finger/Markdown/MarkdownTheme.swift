import AppKit

enum MarkdownTheme {

    // MARK: - Text Attributes

    static var body: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: bodyParagraphStyle
        ]
    }

    static var syntax: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
    }

    // Used for syntax markers on lines where the cursor is not present (Notion-style hiding).
    // Only overrides color so font metrics stay consistent and layout doesn't shift.
    static var hidden: [NSAttributedString.Key: Any] {
        [.foregroundColor: NSColor.clear]
    }

    static var h1: [NSAttributedString.Key: Any] {
        [
            .font: NSFont(name: "Inter-Bold", size: 20) ?? NSFont.boldSystemFont(ofSize: 20),
            .foregroundColor: NSColor.labelColor
        ]
    }

    static var h2: [NSAttributedString.Key: Any] {
        [
            .font: NSFont(name: "Inter-Bold", size: 17) ?? NSFont.boldSystemFont(ofSize: 17),
            .foregroundColor: NSColor.labelColor
        ]
    }

    static var h3: [NSAttributedString.Key: Any] {
        [
            .font: NSFont(name: "Inter-Bold", size: 15) ?? NSFont.boldSystemFont(ofSize: 15),
            .foregroundColor: NSColor.labelColor
        ]
    }

    static var bold: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: 13, weight: .bold)]
    }

    static var italic: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: 13).withTraits(.italic)]
    }

    static var boldItalic: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: 13, weight: .bold).withTraits(.italic)]
    }

    static var strikethrough: [NSAttributedString.Key: Any] {
        [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
    }

    static var code: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.15)
        ]
    }

    static var codeBlock: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.1),
            .paragraphStyle: codeBlockParagraphStyle
        ]
    }

    static var blockquote: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: blockquoteParagraphStyle
        ]
    }

    static var listBullet: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
    }

    // MARK: - Paragraph Styles

    static var bodyParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        return style
    }

    static var blockquoteParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.headIndent = 12
        style.firstLineHeadIndent = 12
        style.lineSpacing = 4
        return style
    }

    static var codeBlockParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.headIndent = 8
        style.firstLineHeadIndent = 8
        style.tailIndent = -8
        style.lineSpacing = 2
        return style
    }

    static var listParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.headIndent = 16
        style.firstLineHeadIndent = 0
        style.lineSpacing = 4
        return style
    }
}

extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let combined = NSFontDescriptor.SymbolicTraits(rawValue: fontDescriptor.symbolicTraits.rawValue | traits.rawValue)
        let descriptor = fontDescriptor.withSymbolicTraits(combined)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
