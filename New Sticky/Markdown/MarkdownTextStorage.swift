import AppKit

// Applies live markdown syntax highlighting while keeping raw text in the backing store.
// Strategy: on every character edit, schedule an async reformat pass using a cancellable task.
// The reformat only sets attributes (no character changes), so processEditing() is skipped
// on the reformat pass via the editedMask guard.
final class MarkdownTextStorage: NSTextStorage {

    private let backing = NSMutableAttributedString()
    private var formatTask: Task<Void, Never>?

    // Set by NoteBodyEditor when selection changes; drives Notion-style syntax hiding
    var cursorRange: NSRange = NSRange(location: 0, length: 0)

    func setCursor(to range: NSRange) {
        cursorRange = range
        DispatchQueue.main.async { [weak self] in
            self?.reformatForCursorChange()
        }
    }

    private func reformatForCursorChange() {
        guard backing.length > 0 else { return }
        applyMarkdownFormatting()
    }

    private var cursorLine: NSRange {
        guard backing.length > 0 else { return NSRange(location: 0, length: 0) }
        let safeLoc = min(cursorRange.location, backing.length - 1)
        return (backing.string as NSString).lineRange(for: NSRange(location: safeLoc, length: 0))
    }

    private func isOnCursorLine(_ lineRange: NSRange) -> Bool {
        let cl = cursorLine
        return NSMaxRange(cl) > lineRange.location && NSMaxRange(lineRange) > cl.location
    }

    // MARK: - NSTextStorage required overrides

    override var string: String { backing.string }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        guard location < backing.length else {
            range?.pointee = NSRange(location: location, length: 0)
            return [:]
        }
        return backing.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        let delta = (str as NSString).length - range.length
        beginEditing()
        backing.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: delta)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        guard range.location != NSNotFound,
              range.length > 0,
              NSMaxRange(range) <= backing.length else { return }
        beginEditing()
        backing.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    // MARK: - Formatting

    override func processEditing() {
        super.processEditing()
        // Only reformat when actual characters change, not when we set attributes
        guard editedMask.contains(.editedCharacters) else { return }
        scheduleReformat()
    }

    private func scheduleReformat() {
        formatTask?.cancel()
        formatTask = Task { @MainActor [weak self] in
            guard !Task.isCancelled, let self else { return }
            self.applyMarkdownFormatting()
        }
    }

    private func applyMarkdownFormatting() {
        let fullRange = NSRange(location: 0, length: backing.length)
        guard fullRange.length > 0 else { return }

        beginEditing()
        // Reset all to body style
        backing.setAttributes(MarkdownTheme.body, range: fullRange)

        let text = backing.string as NSString

        // Walk each line for block-level formatting
        var pos = 0
        var inCodeBlock = false
        var codeBlockStart = 0

        while pos < text.length {
            let lineRange = text.lineRange(for: NSRange(location: pos, length: 0))

            let line = text.substring(with: lineRange)
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Fenced code block tracking
            if trimmed.hasPrefix("```") {
                if !inCodeBlock {
                    inCodeBlock = true
                    codeBlockStart = lineRange.location
                    backing.addAttributes(MarkdownTheme.syntax, range: lineRange)
                } else {
                    inCodeBlock = false
                    let blockRange = NSRange(location: codeBlockStart, length: NSMaxRange(lineRange) - codeBlockStart)
                    backing.addAttributes(MarkdownTheme.codeBlock, range: blockRange)
                }
                pos = NSMaxRange(lineRange)
                continue
            }

            if inCodeBlock {
                backing.addAttributes(MarkdownTheme.codeBlock, range: lineRange)
                pos = NSMaxRange(lineRange)
                continue
            }

            let onCursor = isOnCursorLine(lineRange)
            let markerAttrs = onCursor ? MarkdownTheme.syntax : MarkdownTheme.hidden

            // Headings
            if trimmed.hasPrefix("### ") {
                let prefixLen = min(4, lineRange.length)
                let prefixRange = NSRange(location: lineRange.location, length: prefixLen)
                let contentRange = NSRange(location: lineRange.location + prefixLen, length: lineRange.length - prefixLen)
                backing.addAttributes(markerAttrs, range: prefixRange)
                if contentRange.length > 0 { backing.addAttributes(MarkdownTheme.h3, range: contentRange) }
            } else if trimmed.hasPrefix("## ") {
                let prefixLen = min(3, lineRange.length)
                let prefixRange = NSRange(location: lineRange.location, length: prefixLen)
                let contentRange = NSRange(location: lineRange.location + prefixLen, length: lineRange.length - prefixLen)
                backing.addAttributes(markerAttrs, range: prefixRange)
                if contentRange.length > 0 { backing.addAttributes(MarkdownTheme.h2, range: contentRange) }
            } else if trimmed.hasPrefix("# ") {
                let prefixLen = min(2, lineRange.length)
                let prefixRange = NSRange(location: lineRange.location, length: prefixLen)
                let contentRange = NSRange(location: lineRange.location + prefixLen, length: lineRange.length - prefixLen)
                backing.addAttributes(markerAttrs, range: prefixRange)
                if contentRange.length > 0 { backing.addAttributes(MarkdownTheme.h1, range: contentRange) }
            }
            // Blockquote
            else if trimmed.hasPrefix("> ") {
                let prefixLen = line.distance(from: line.startIndex,
                                              to: line.range(of: "> ")!.upperBound)
                let prefixRange = NSRange(location: lineRange.location, length: prefixLen)
                let contentRange = NSRange(location: lineRange.location + prefixLen, length: lineRange.length - prefixLen)
                backing.addAttributes(markerAttrs, range: prefixRange)
                if contentRange.length > 0 { backing.addAttributes(MarkdownTheme.blockquote, range: contentRange) }
            }
            // Bullet list
            else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                let prefixLen = line.distance(from: line.startIndex,
                                              to: (line.range(of: "- ") ?? line.range(of: "* ") ?? line.range(of: "+ ")!).upperBound)
                let prefixRange = NSRange(location: lineRange.location, length: prefixLen)
                backing.addAttributes(markerAttrs, range: prefixRange)
            }
            // Horizontal rule
            else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                backing.addAttributes(markerAttrs, range: lineRange)
            }

            pos = NSMaxRange(lineRange)
        }

        // Inline formatting via regex on full text
        applyInlineFormatting(in: fullRange, text: text)

        endEditing()
    }

    private func applyInlineFormatting(in range: NSRange, text: NSString) {
        // Bold-italic: ***text*** or ___text___
        applyPattern("\\*{3}(.+?)\\*{3}|_{3}(.+?)_{3}", in: range, text: text, contentAttrs: MarkdownTheme.boldItalic, markerLen: 3)

        // Bold: **text** or __text__
        applyPattern("\\*{2}(.+?)\\*{2}|_{2}(.+?)_{2}", in: range, text: text, contentAttrs: MarkdownTheme.bold, markerLen: 2)

        // Italic: *text* or _text_  (single, not preceded/followed by same char)
        applyPattern("(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)|(?<!_)_(?!_)(.+?)(?<!_)_(?!_)", in: range, text: text, contentAttrs: MarkdownTheme.italic, markerLen: 1)

        // Strikethrough: ~~text~~
        applyPattern("~~(.+?)~~", in: range, text: text, contentAttrs: MarkdownTheme.strikethrough, markerLen: 2)

        // Inline code: `text`
        applyInlineCode(in: range, text: text)

        // Checkboxes: [ ] or [x]
        applyCheckboxes(in: range, text: text)
    }

    private func applyPattern(
        _ pattern: String,
        in range: NSRange,
        text: NSString,
        contentAttrs: [NSAttributedString.Key: Any],
        markerLen: Int
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        regex.enumerateMatches(in: text as String, range: range) { match, _, _ in
            guard let match else { return }
            let fullRange = match.range
            guard fullRange.length > 2 * markerLen else { return }

            let matchLineRange = (backing.string as NSString).lineRange(for: NSRange(location: fullRange.location, length: 0))
            let markerAttrs = isOnCursorLine(matchLineRange) ? MarkdownTheme.syntax : MarkdownTheme.hidden

            let openMarker = NSRange(location: fullRange.location, length: markerLen)
            let closeMarker = NSRange(location: NSMaxRange(fullRange) - markerLen, length: markerLen)
            let contentRange = NSRange(location: fullRange.location + markerLen,
                                       length: fullRange.length - 2 * markerLen)

            backing.addAttributes(markerAttrs, range: openMarker)
            if contentRange.length > 0 { backing.addAttributes(contentAttrs, range: contentRange) }
            backing.addAttributes(markerAttrs, range: closeMarker)
        }
    }

    private func applyInlineCode(in range: NSRange, text: NSString) {
        guard let regex = try? NSRegularExpression(pattern: "`([^`]+)`", options: []) else { return }
        regex.enumerateMatches(in: text as String, range: range) { match, _, _ in
            guard let match else { return }
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            let matchLineRange = (backing.string as NSString).lineRange(for: NSRange(location: fullRange.location, length: 0))
            let markerAttrs = isOnCursorLine(matchLineRange) ? MarkdownTheme.syntax : MarkdownTheme.hidden
            backing.addAttributes(markerAttrs, range: NSRange(location: fullRange.location, length: 1))
            if contentRange.length > 0 { backing.addAttributes(MarkdownTheme.code, range: contentRange) }
            backing.addAttributes(markerAttrs, range: NSRange(location: NSMaxRange(fullRange) - 1, length: 1))
        }
    }

    private func applyCheckboxes(in range: NSRange, text: NSString) {
        guard let regex = try? NSRegularExpression(pattern: "^(\\[[ xX]\\])", options: .anchorsMatchLines) else { return }
        regex.enumerateMatches(in: text as String, range: range) { match, _, _ in
            guard let match else { return }
            let matchLineRange = (backing.string as NSString).lineRange(for: NSRange(location: match.range.location, length: 0))
            let markerAttrs = isOnCursorLine(matchLineRange) ? MarkdownTheme.listBullet : MarkdownTheme.hidden
            backing.addAttributes(markerAttrs, range: match.range)
        }
    }
}
