import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        webView.alphaValue = 0
        context.coordinator.lastHTML = html
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard html != context.coordinator.lastHTML else { return }
        context.coordinator.lastHTML = html
        webView.alphaValue = 0
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?

        // swiftlint:disable:next implicitly_unwrapped_optional
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                webView.animator().alphaValue = 1
            }
        }
    }
}
