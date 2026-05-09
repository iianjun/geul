import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let fileURL: URL?
    let theme: Theme
    let readerAlignment: ReaderAlignment
    let findRequest: FindRequest
    let onFindResult: (FindResult) -> Void
    let onMarkdownReload: (String) -> Void

    init(
        html: String,
        fileURL: URL?,
        theme: Theme,
        readerAlignment: ReaderAlignment,
        findRequest: FindRequest = .initial,
        onFindResult: @escaping (FindResult) -> Void = { _ in },
        onMarkdownReload: @escaping (String) -> Void = { _ in }
    ) {
        self.html = html
        self.fileURL = fileURL
        self.theme = theme
        self.readerAlignment = readerAlignment
        self.findRequest = findRequest
        self.onFindResult = onFindResult
        self.onMarkdownReload = onMarkdownReload
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFindResult: onFindResult, onMarkdownReload: onMarkdownReload)
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
        context.coordinator.lastAppliedTheme = theme
        context.coordinator.lastAppliedReaderAlignment = readerAlignment
        context.coordinator.queueFindRequestIfNeeded(findRequest)
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onFindResult = onFindResult
        context.coordinator.onMarkdownReload = onMarkdownReload

        if html != context.coordinator.lastHTML {
            // Content changed: full reload. The new HTML embeds the current
            // theme, so update the applied baseline in lockstep.
            context.coordinator.lastHTML = html
            context.coordinator.lastAppliedTheme = theme
            context.coordinator.lastAppliedReaderAlignment = readerAlignment
            context.coordinator.queueFindRequestIfNeeded(findRequest)
            webView.alphaValue = 0
            webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
            return
        }

        if context.coordinator.lastAppliedTheme != theme {
            context.coordinator.lastAppliedTheme = theme
            context.coordinator.applyTheme(theme)
        }

        if context.coordinator.lastAppliedReaderAlignment != readerAlignment {
            context.coordinator.lastAppliedReaderAlignment = readerAlignment
            context.coordinator.applyReaderAlignment(readerAlignment)
        }

        context.coordinator.handleFindRequest(findRequest, in: webView)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?
        var fileURL: URL?
        var fileWatcher: FileWatcher?
        weak var webView: WKWebView?
        var lastAppliedTheme: Theme?
        var lastAppliedReaderAlignment: ReaderAlignment?
        var onFindResult: (FindResult) -> Void
        var onMarkdownReload: (String) -> Void
        var lastAppliedFindRequestID = FindRequest.initial.id
        // A theme change that arrived before the first navigation finished.
        // Drained in didFinish so the fresh WebView picks it up.
        private var pendingThemeApply: Theme?
        private var pendingReaderAlignmentApply: ReaderAlignment?
        private var pendingFindRequests = PendingFindRequestQueue()

        init(
            onFindResult: @escaping (FindResult) -> Void,
            onMarkdownReload: @escaping (String) -> Void
        ) {
            self.onFindResult = onFindResult
            self.onMarkdownReload = onMarkdownReload
        }

        // swiftlint:disable:next implicitly_unwrapped_optional
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                webView.animator().alphaValue = 1
            }

            if self.webView == nil {
                self.webView = webView
                if let window = webView.window as? MarkdownWindow {
                    window.attachMarkdownWebView(webView)
                }
                startWatching()
            }

            if let pending = pendingThemeApply {
                pendingThemeApply = nil
                applyTheme(pending)
            }

            if let pending = pendingReaderAlignmentApply {
                pendingReaderAlignmentApply = nil
                applyReaderAlignment(pending)
            }

            drainPendingFindRequest(in: webView)
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
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    guard let webView else { return }
                    onMarkdownReload(markdown)
                    webView.callAsyncJavaScript(
                        "return await updateContent(html);",
                        arguments: ["html": body],
                        in: nil,
                        in: .page
                    ) { result in
                        switch result {
                        case .success(let value):
                            self.restoreNativeFindAfterContentUpdate(from: value, in: webView)
                        case .failure(let error):
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

        // MARK: - Find Bridge

        func queueFindRequestIfNeeded(_ request: FindRequest) {
            pendingFindRequests.enqueue(
                request,
                lastAppliedRequestID: lastAppliedFindRequestID
            )
        }

        func handleFindRequest(_ request: FindRequest, in webView: WKWebView) {
            guard request.id > lastAppliedFindRequestID else { return }

            if request.action == .none {
                lastAppliedFindRequestID = request.id
                return
            }

            guard !webView.isLoading else {
                queueFindRequestIfNeeded(request)
                return
            }

            applyFindRequest(request, in: webView)
        }

        private func drainPendingFindRequest(in webView: WKWebView) {
            for request in pendingFindRequests.drain() where request.id > lastAppliedFindRequestID {
                applyFindRequest(request, in: webView)
            }
        }

        private func applyFindRequest(_ request: FindRequest, in webView: WKWebView) {
            guard let script = Self.findScript(for: request.action) else {
                lastAppliedFindRequestID = request.id
                return
            }

            lastAppliedFindRequestID = request.id
            webView.evaluateJavaScript(script) { [weak self, weak webView] result, error in
                if let error {
                    print("[geul] find command error: \(error)")
                }
                guard let self else { return }
                guard self.lastAppliedFindRequestID == request.id else { return }
                guard let webView else {
                    self.publishFindResult(from: result)
                    return
                }

                self.handleFindScriptResult(
                    result,
                    for: request.action,
                    requestID: request.id,
                    in: webView
                )
            }
        }

        private func handleFindScriptResult(
            _ value: Any?,
            for action: FindAction,
            requestID: Int,
            in webView: WKWebView
        ) {
            guard let result = Self.findResult(from: value) else { return }

            switch action {
            case .none:
                break
            case .search(let query):
                runNativeFindIfNeeded(
                    query: query,
                    backwards: false,
                    result: result,
                    requestID: requestID,
                    in: webView
                )
            case .next:
                runNativeFindIfNeeded(
                    query: result.query,
                    backwards: false,
                    result: result,
                    requestID: requestID,
                    in: webView
                )
            case .previous:
                runNativeFindIfNeeded(
                    query: result.query,
                    backwards: true,
                    result: result,
                    requestID: requestID,
                    in: webView
                )
            case .clear:
                clearNativeFindSelection(in: webView)
                publishFindResult(result)
            }
        }

        private func restoreNativeFindAfterContentUpdate(from value: Any?, in webView: WKWebView) {
            guard let result = Self.findResult(from: value) else { return }

            runNativeFindIfNeeded(
                query: result.query,
                backwards: false,
                result: result,
                requestID: lastAppliedFindRequestID,
                in: webView
            )
        }

        private func runNativeFindIfNeeded(
            query: String,
            backwards: Bool,
            result: FindResult,
            requestID: Int,
            in webView: WKWebView
        ) {
            guard !query.isEmpty, result.hasMatches else {
                clearNativeFindSelection(in: webView)
                publishFindResult(result)
                return
            }

            let configuration = WKFindConfiguration()
            configuration.backwards = backwards
            configuration.caseSensitive = false
            configuration.wraps = true

            webView.find(query, configuration: configuration) { [weak self] nativeResult in
                guard let self else { return }
                guard self.lastAppliedFindRequestID == requestID else { return }

                if nativeResult.matchFound {
                    self.publishFindResult(result)
                } else {
                    let emptyResult = FindResult(query: query, currentIndex: -1, total: 0)
                    self.publishFindResult(emptyResult)
                }
            }
        }

        private func clearNativeFindSelection(in webView: WKWebView) {
            webView.evaluateJavaScript(
                "window.getSelection && window.getSelection().removeAllRanges();",
                completionHandler: nil
            )
        }

        private func publishFindResult(from value: Any?) {
            guard let result = Self.findResult(from: value) else { return }
            publishFindResult(result)
        }

        private func publishFindResult(_ result: FindResult) {
            DispatchQueue.main.async { [onFindResult] in
                onFindResult(result)
            }
        }

        private static func jsStringEncode(_ string: String) -> String? {
            guard let data = try? JSONSerialization.data(
                withJSONObject: string,
                options: .fragmentsAllowed
            ) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        private static func findScript(for action: FindAction) -> String? {
            let fallback = "({ query: '', currentIndex: -1, total: 0 })"

            switch action {
            case .none:
                return nil
            case .search(let query):
                guard let encoded = jsStringEncode(query) else { return fallback }
                return """
                (window.geulFind ? window.geulFind.search(\(encoded)) : \(fallback))
                """
            case .next:
                return """
                (window.geulFind ? window.geulFind.next() : \(fallback))
                """
            case .previous:
                return """
                (window.geulFind ? window.geulFind.previous() : \(fallback))
                """
            case .clear:
                return """
                (window.geulFind ? window.geulFind.clear() : \(fallback))
                """
            }
        }

        private static func findResult(from value: Any?) -> FindResult? {
            guard let value, !(value is NSNull) else { return nil }

            let dictionary: [String: Any]
            if let swiftDictionary = value as? [String: Any] {
                dictionary = swiftDictionary
            } else if let nsDictionary = value as? NSDictionary {
                dictionary = nsDictionary as? [String: Any] ?? [:]
            } else {
                return nil
            }

            return FindResult(
                query: dictionary["query"] as? String ?? "",
                currentIndex: intValue(from: dictionary["currentIndex"]) ?? -1,
                total: intValue(from: dictionary["total"]) ?? 0
            )
        }

        private static func intValue(from value: Any?) -> Int? {
            if let int = value as? Int {
                return int
            }

            if let number = value as? NSNumber {
                return number.intValue
            }

            return nil
        }

        deinit {
            fileWatcher?.stop()
        }
    }
}

extension MarkdownWebView.Coordinator {
    func applyTheme(_ theme: Theme) {
        // Queue until the first navigation completes; otherwise the
        // <style id="geul-theme"> element doesn't exist yet.
        guard let webView, webView.isLoading == false else {
            pendingThemeApply = theme
            return
        }
        do {
            let sanitized = ThemeSanitizer.sanitized(theme.colors)
            let data = try JSONEncoder().encode(sanitized)
            guard let colorsJSON = String(data: data, encoding: .utf8) else { return }
            let hljsKey = ThemeSanitizer.hljsVariantKey(for: theme)
            let script = "setTheme(\(colorsJSON), '\(hljsKey)')"
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    print("[geul] setTheme error: \(error)")
                }
            }
        } catch {
            print("[geul] Failed to encode theme colors: \(error)")
        }
    }

    func applyReaderAlignment(_ alignment: ReaderAlignment) {
        guard let webView, webView.isLoading == false else {
            pendingReaderAlignmentApply = alignment
            return
        }

        let alignmentClass = "reader-align-\(alignment.rawValue)"
        let script = """
        (() => {
            const content = document.getElementById('content');
            if (!content) { return; }
            content.classList.remove(
                'reader-align-left',
                'reader-align-center',
                'reader-align-right'
            );
            content.classList.add('\(alignmentClass)');
        })();
        """
        webView.evaluateJavaScript(script) { _, error in
            if let error {
                print("[geul] applyReaderAlignment error: \(error)")
            }
        }
    }
}
