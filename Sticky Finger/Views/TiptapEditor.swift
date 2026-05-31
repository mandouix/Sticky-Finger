import AppKit
import WebKit
import SwiftUI

struct TiptapEditor: NSViewRepresentable {

    @Binding var text: String
    @Binding var editorHeight: CGFloat
    var bridge: EditorBridge?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "update")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        if let url = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        bridge?.webView = webView
        context.coordinator.bridge = bridge

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.bridge = bridge
        if bridge?.webView == nil { bridge?.webView = webView }

        guard context.coordinator.isLoaded, !context.coordinator.isUpdatingFromJS else { return }
        guard context.coordinator.lastSyncedText != text else { return }
        context.coordinator.pushContent(text, to: webView, init: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, editorHeight: $editorHeight)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        var text: Binding<String>
        var editorHeight: Binding<CGFloat>
        var isLoaded = false
        var isUpdatingFromJS = false
        var lastSyncedText = ""
        var bridge: EditorBridge?

        init(text: Binding<String>, editorHeight: Binding<CGFloat>) {
            self.text = text
            self.editorHeight = editorHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            let markdown = text.wrappedValue
            pushContent(markdown, to: webView, init: true)
            if let accent = bridge?.pendingAccent {
                webView.evaluateJavaScript(
                    "document.documentElement.style.setProperty('--accent','\(accent)')"
                ) { _, _ in }
            }
        }

        func pushContent(_ markdown: String, to webView: WKWebView, `init` isInit: Bool) {
            guard let json = try? JSONEncoder().encode(markdown),
                  let jsonStr = String(data: json, encoding: .utf8) else { return }
            let call = isInit
                ? "window.editorAPI.initEditor(\(jsonStr))"
                : "window.editorAPI.setMarkdown(\(jsonStr))"
            webView.evaluateJavaScript(call) { _, _ in }
            lastSyncedText = markdown
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "update",
                  let body = message.body as? [String: Any] else { return }

            // Toolbar state update
            if let toolbar = body["toolbar"] as? [String: Any] {
                DispatchQueue.main.async {
                    self.bridge?.state.visible     = toolbar["visible"] as? Bool ?? false
                    self.bridge?.state.bold        = toolbar["bold"]    as? Bool ?? false
                    self.bridge?.state.italic      = toolbar["italic"]  as? Bool ?? false
                    self.bridge?.state.underline   = toolbar["underline"] as? Bool ?? false
                    self.bridge?.state.strike      = toolbar["strike"]  as? Bool ?? false
                    self.bridge?.state.heading     = toolbar["heading"] as? Int  ?? 0
                    self.bridge?.state.bulletList  = toolbar["bulletList"]  as? Bool ?? false
                    self.bridge?.state.orderedList = toolbar["orderedList"] as? Bool ?? false
                    self.bridge?.state.taskList    = toolbar["taskList"]    as? Bool ?? false
                    self.bridge?.state.code        = toolbar["code"]        as? Bool ?? false
                    self.bridge?.state.codeBlock   = toolbar["codeBlock"]   as? Bool ?? false
                    self.bridge?.state.blockquote  = toolbar["blockquote"]  as? Bool ?? false
                    if let r = toolbar["rect"] as? [String: Double] {
                        self.bridge?.state.selectionRect = CGRect(
                            x: r["x"] ?? 0, y: r["y"] ?? 0,
                            width: r["w"] ?? 0, height: r["h"] ?? 0
                        )
                    }
                }
                return
            }

            if let scroll = body["scroll"] as? [String: Double] {
                DispatchQueue.main.async {
                    self.bridge?.scrollTop    = CGFloat(scroll["top"]    ?? 0)
                    self.bridge?.scrollBottom = CGFloat(scroll["bottom"] ?? 0)
                }
                return
            }

            isUpdatingFromJS = true
            defer { isUpdatingFromJS = false }

            if let content = body["content"] as? String {
                lastSyncedText = content
                text.wrappedValue = content
            }
            if let height = body["height"] as? Double {
                let h = max(56, CGFloat(height))
                if abs(editorHeight.wrappedValue - h) > 1 {
                    editorHeight.wrappedValue = h
                }
            }
            if let tl = body["textLength"] as? Int {
                bridge?.visibleCharCount = tl
            }
        }
    }
}
