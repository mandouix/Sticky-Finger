import AppKit
import SwiftUI

struct NoteBodyEditor: NSViewRepresentable {

    @Binding var text: String
    @Binding var editorHeight: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        let storage = MarkdownTextStorage()
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)

        let textView = NSTextView(frame: .zero, textContainer: container)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.focusRingType = .none
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = .labelColor
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.delegate = context.coordinator

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.documentView = textView

        if !text.isEmpty {
            storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
            DispatchQueue.main.async {
                context.coordinator.reportHeight(textView)
            }
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView,
              let storage = textView.textStorage as? MarkdownTextStorage else { return }

        if storage.string != text {
            let selected = textView.selectedRange()
            storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)
            let safeRange = NSRange(location: min(selected.location, storage.length), length: 0)
            textView.setSelectedRange(safeRange)
            context.coordinator.reportHeight(textView)
        }

        // Keep text view frame tall enough to show all content without scrolling
        if let lm = textView.layoutManager, let tc = textView.textContainer {
            lm.ensureLayout(for: tc)
            let contentH = ceil(lm.usedRect(for: tc).height) + 16
            let minH = max(contentH, scrollView.bounds.height)
            if abs(textView.frame.height - minH) > 1 {
                textView.frame.size.height = minH
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, editorHeight: $editorHeight)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var editorHeight: Binding<CGFloat>

        init(text: Binding<String>, editorHeight: Binding<CGFloat>) {
            self.text = text
            self.editorHeight = editorHeight
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            reportHeight(textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let storage = textView.textStorage as? MarkdownTextStorage else { return }
            storage.setCursor(to: textView.selectedRange())
        }

        func reportHeight(_ textView: NSTextView) {
            guard let lm = textView.layoutManager, let tc = textView.textContainer else { return }
            lm.ensureLayout(for: tc)
            let h = ceil(lm.usedRect(for: tc).height) + 16
            DispatchQueue.main.async {
                self.editorHeight.wrappedValue = max(56, h)
            }
        }
    }
}
