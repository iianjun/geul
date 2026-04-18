import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let fileURL: URL?
    let lightTheme: Theme
    let darkTheme: Theme

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
        context.coordinator.fileURL = fileURL
        context.coordinator.lastAppliedLight = lightTheme
        context.coordinator.lastAppliedDark = darkTheme
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if html != context.coordinator.lastHTML {
            // Content changed: full reload. The new HTML embeds the current
            // themes, so update the applied baseline in lockstep.
            context.coordinator.lastHTML = html
            context.coordinator.lastAppliedLight = lightTheme
            context.coordinator.lastAppliedDark = darkTheme
            webView.alphaValue = 0
            webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
            return
        }

        if context.coordinator.lastAppliedLight != lightTheme
            || context.coordinator.lastAppliedDark != darkTheme {
            context.coordinator.lastAppliedLight = lightTheme
            context.coordinator.lastAppliedDark = darkTheme
            context.coordinator.applyTheme(light: lightTheme, dark: darkTheme)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?
        var fileURL: URL?
        var fileWatcher: FileWatcher?
        weak var webView: WKWebView?
        var lastAppliedLight: Theme?
        var lastAppliedDark: Theme?
        // A theme change that arrived before the first navigation finished.
        // Drained in didFinish so the fresh WebView picks it up.
        private var pendingThemeApply: (Theme, Theme)?

        // swiftlint:disable:next implicitly_unwrapped_optional
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                webView.animator().alphaValue = 1
            }

            if self.webView == nil {
                self.webView = webView
                startWatching()
            }

            if let (light, dark) = pendingThemeApply {
                pendingThemeApply = nil
                applyTheme(light: light, dark: dark)
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        // MARK: - File Watching

        private func startWatching() {
            guard let url = fileURL else { return }
            let watcher = FileWatcher(
                url: url,
                onChange: { [weak self] in self?.handleFileChange() },
                onDelete: { [weak self] deleted in self?.handleDelete(deleted) }
            )
            watcher.start()
            fileWatcher = watcher
        }

        private func handleFileChange() {
            guard let url = fileURL else { return }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let markdown = try? String(contentsOf: url, encoding: .utf8) else { return }
                let body = MarkdownRenderer.render(markdown)
                guard let encoded = Self.jsStringEncode(body) else { return }
                DispatchQueue.main.async {
                    self?.webView?.evaluateJavaScript("updateContent(\(encoded))") { _, error in
                        if let error {
                            print("[geul] updateContent error: \(error)")
                        }
                    }
                }
            }
        }

        private func handleDelete(_ deleted: Bool) {
            guard let fileName = fileURL?.lastPathComponent else { return }
            let title = deleted ? "\(fileName) (deleted)" : fileName
            webView?.window?.title = title
        }

        // MARK: - Theme Patching

        func applyTheme(light: Theme, dark: Theme) {
            // Queue until the first navigation completes; otherwise the
            // <style id="geul-theme"> element doesn't exist yet.
            guard let webView, webView.isLoading == false else {
                pendingThemeApply = (light, dark)
                return
            }
            do {
                let sanitizedLight = ThemeSanitizer.sanitized(light.colors)
                let sanitizedDark = ThemeSanitizer.sanitized(dark.colors)
                let lightData = try JSONEncoder().encode(sanitizedLight)
                let darkData = try JSONEncoder().encode(sanitizedDark)
                guard let lightJSON = String(data: lightData, encoding: .utf8),
                      let darkJSON = String(data: darkData, encoding: .utf8) else { return }
                let script = "setTheme(\(lightJSON), \(darkJSON), '\(light.type.rawValue)', '\(dark.type.rawValue)')"
                webView.evaluateJavaScript(script) { _, error in
                    if let error {
                        print("[geul] setTheme error: \(error)")
                    }
                }
            } catch {
                print("[geul] Failed to encode theme colors: \(error)")
            }
        }

        private static func jsStringEncode(_ string: String) -> String? {
            guard let data = try? JSONSerialization.data(
                withJSONObject: string,
                options: .fragmentsAllowed
            ) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        deinit {
            fileWatcher?.stop()
        }
    }
}
