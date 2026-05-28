import WebKit
import CoreGraphics

final class EditorBridge: ObservableObject {
    struct FormatState {
        var visible = false
        var selectionRect: CGRect = .zero
        var bold = false
        var italic = false
        var underline = false
        var strike = false
        var heading = 0
        var bulletList = false
        var orderedList = false
        var taskList = false
        var code = false
        var codeBlock = false
        var blockquote = false
    }

    @Published var state = FormatState()
    @Published var isWindowHovered = false
    @Published var scrollTop: CGFloat = 0
    @Published var scrollBottom: CGFloat = 0
    @Published var visibleCharCount: Int = 0
    weak var webView: WKWebView?

    private(set) var pendingAccent: String = "CanvasText"

    private func exec(_ js: String) {
        webView?.evaluateJavaScript(js) { _, _ in }
    }

    func setAccentColor(_ css: String) {
        pendingAccent = css
        exec("document.documentElement.style.setProperty('--accent','\(css)')")
    }

    func toggleBold()        { exec("window.editorAPI.toggleBold()") }
    func toggleItalic()      { exec("window.editorAPI.toggleItalic()") }
    func toggleUnderline()   { exec("window.editorAPI.toggleUnderline()") }
    func toggleStrike()      { exec("window.editorAPI.toggleStrike()") }
    func setHeading(_ level: Int) { exec("window.editorAPI.setHeading(\(level))") }
    func toggleBullet()      { exec("window.editorAPI.toggleBullet()") }
    func toggleOrdered()     { exec("window.editorAPI.toggleOrdered()") }
    func toggleTask()        { exec("window.editorAPI.toggleTask()") }
    func toggleCode()        { exec("window.editorAPI.toggleCode()") }
    func toggleCodeBlock()   { exec("window.editorAPI.toggleCodeBlock()") }
    func toggleBlockquote()  { exec("window.editorAPI.toggleBlockquote()") }
}
