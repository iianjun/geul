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
        webView.loadHTMLString(html, baseURL: AppResource.webBaseURL)
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
            webView.loadHTMLString(html, baseURL: AppResource.webBaseURL)
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
                        WebViewScriptBridge.updateContentScript,
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
            guard let script = WebViewScriptBridge.findScript(for: request.action) else {
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

            webView.evaluateJavaScript(
                WebViewScriptBridge.captureScrollPositionScript
            ) { [weak self, weak webView] scrollSnapshot, _ in
                guard let self, let webView else { return }

                self.runNativeFindIfNeeded(
                    query: result.query,
                    backwards: false,
                    result: result,
                    requestID: self.lastAppliedFindRequestID,
                    in: webView
                ) {
                    webView.callAsyncJavaScript(
                        WebViewScriptBridge.restoreScrollPositionScript,
                        arguments: ["snapshot": scrollSnapshot ?? NSNull()],
                        in: nil,
                        in: .page
                    ) { result in
                        if case .failure(let error) = result {
                            print("[geul] restore scroll error: \(error)")
                        }
                    }
                }
            }
        }

        private func runNativeFindIfNeeded(
            query: String,
            backwards: Bool,
            result: FindResult,
            requestID: Int,
            in webView: WKWebView,
            completion: (() -> Void)? = nil
        ) {
            guard !query.isEmpty, result.hasMatches else {
                clearNativeFindSelection(in: webView)
                publishFindResult(result)
                completion?()
                return
            }

            let configuration = WKFindConfiguration()
            configuration.backwards = backwards
            configuration.caseSensitive = false
            configuration.wraps = true

            webView.find(query, configuration: configuration) { [weak self] _ in
                guard let self else { return }
                guard self.lastAppliedFindRequestID == requestID else {
                    completion?()
                    return
                }

                self.publishFindResult(result)
                completion?()
            }
        }

        private func clearNativeFindSelection(in webView: WKWebView) {
            webView.evaluateJavaScript(
                WebViewScriptBridge.clearSelectionScript,
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

private enum WebViewScriptBridge {
    static let updateContentScript = "return await window.geul.updateContent(html);"
    static let setThemeScript = "return await window.geul.setTheme(colors, hljsKey);"
    static let setReaderAlignmentScript = "window.geul.setReaderAlignment(alignment);"
    static let captureScrollPositionScript = "window.geul.captureScrollPosition();"
    static let restoreScrollPositionScript = "window.geul.restoreScrollPosition(snapshot);"
    static let clearSelectionScript = "window.getSelection && window.getSelection().removeAllRanges();"

    private static let fallbackFindResult = "({ query: '', currentIndex: -1, total: 0 })"

    static func findScript(for action: FindAction) -> String? {
        switch action {
        case .none:
            return nil
        case .search(let query):
            guard let encoded = jsonLiteral(query) else { return fallbackFindResult }
            return """
            (window.geulFind ? window.geulFind.search(\(encoded)) : \(fallbackFindResult))
            """
        case .next:
            return """
            (window.geulFind ? window.geulFind.next() : \(fallbackFindResult))
            """
        case .previous:
            return """
            (window.geulFind ? window.geulFind.previous() : \(fallbackFindResult))
            """
        case .clear:
            return """
            (window.geulFind ? window.geulFind.clear() : \(fallbackFindResult))
            """
        }
    }

    private static func jsonLiteral(_ value: String) -> String? {
        guard let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: .fragmentsAllowed
        ) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension MarkdownWebView.Coordinator {
    func applyTheme(_ theme: Theme) {
        guard let webView, webView.isLoading == false else {
            pendingThemeApply = theme
            return
        }

        let sanitized = ThemeSanitizer.sanitized(theme.colors)
        let hljsKey = ThemeSanitizer.hljsVariantKey(for: theme)
        webView.callAsyncJavaScript(
            WebViewScriptBridge.setThemeScript,
            arguments: ["colors": sanitized, "hljsKey": hljsKey],
            in: nil,
            in: .page
        ) { result in
            if case .failure(let error) = result {
                print("[geul] setTheme error: \(error)")
            }
        }
    }

    func applyReaderAlignment(_ alignment: ReaderAlignment) {
        guard let webView, webView.isLoading == false else {
            pendingReaderAlignmentApply = alignment
            return
        }

        webView.callAsyncJavaScript(
            WebViewScriptBridge.setReaderAlignmentScript,
            arguments: ["alignment": alignment.rawValue],
            in: nil,
            in: .page
        ) { result in
            if case .failure(let error) = result {
                print("[geul] applyReaderAlignment error: \(error)")
            }
        }
    }
}
