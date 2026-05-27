import AppKit
import WebKit
import SwiftUI

struct TiptapEditor: NSViewRepresentable {

    @Binding var text: String
    @Binding var editorHeight: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "update")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        if let url = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
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

        init(text: Binding<String>, editorHeight: Binding<CGFloat>) {
            self.text = text
            self.editorHeight = editorHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            // Use the current binding value — onAppear will have set it by now in typical flows.
            let markdown = text.wrappedValue
            pushContent(markdown, to: webView, init: true)
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
        }
    }
}
