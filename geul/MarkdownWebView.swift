import Combine
import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let fileURL: URL?

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
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard html != context.coordinator.lastHTML else { return }
        context.coordinator.lastHTML = html
        webView.alphaValue = 0
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?
        var fileURL: URL?
        var fileWatcher: FileWatcher?
        weak var webView: WKWebView?
        private var themeCancellables = Set<AnyCancellable>()

        // swiftlint:disable:next implicitly_unwrapped_optional
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                webView.animator().alphaValue = 1
            }

            if self.webView == nil {
                self.webView = webView
                startWatching()
                observeThemeChanges()
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

        // MARK: - Theme Observation

        private func observeThemeChanges() {
            let store = ThemeStore.shared
            store.$resolvedLight
                .combineLatest(store.$resolvedDark)
                .dropFirst()
                .debounce(for: .milliseconds(16), scheduler: DispatchQueue.main)
                .removeDuplicates(by: ==)
                .sink { [weak self] light, dark in
                    self?.applyTheme(light: light, dark: dark)
                }
                .store(in: &themeCancellables)
        }

        private func applyTheme(light: Theme, dark: Theme) {
            guard let webView else { return }
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
