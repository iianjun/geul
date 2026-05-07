import SwiftUI

struct ContentView: View {
    let fileURL: URL?
    @ObservedObject var findCommandBridge: FindCommandBridge
    @StateObject private var themeStore = ThemeStore.shared
    @State private var html: String?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var isFindBarVisible = false
    @State private var findQuery = ""
    @State private var findRequest = FindRequest.initial
    @State private var findRequestID = FindRequest.initial.id
    @State private var findResult = FindResult.empty
    @State private var findFocusRequestID = 0

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if let html {
                MarkdownWebView(
                    html: html,
                    fileURL: fileURL,
                    theme: themeStore.resolved,
                    findRequest: findRequest,
                    onFindResult: handleFindResult
                )
                .overlay(alignment: .topTrailing) {
                    if isFindBarVisible {
                        FindBar(
                            query: $findQuery,
                            result: findResult,
                            focusRequestID: findFocusRequestID,
                            onPrevious: previousMatch,
                            onNext: nextMatch,
                            onClose: closeFind
                        )
                        .padding(12)
                        .transition(.opacity)
                    }
                }
                .transition(.opacity)
            }

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .transition(.opacity)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.12), value: isFindBarVisible)
        .onReceive(findCommandBridge.$request, perform: handleFindMenuRequest)
        .onChange(of: findQuery) { _, newQuery in
            search(newQuery)
        }
        .onChange(of: html) { _, _ in
            updateFindAvailability()
        }
        .task {
            await loadFile()
        }
    }

    private func loadFile() async {
        guard let fileURL else {
            isLoading = false
            errorMessage = "Usage: geul <file.md>"
            return
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            isLoading = false
            errorMessage = "File not found: \(fileURL.path)"
            return
        }

        do {
            let markdown = try String(contentsOf: fileURL, encoding: .utf8)
            let title = fileURL.lastPathComponent
            let theme = themeStore.resolved
            let rendered = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    let body = MarkdownRenderer.render(markdown)
                    let result = HTMLTemplate.compose(
                        body: body,
                        title: title,
                        theme: theme
                    )
                    continuation.resume(returning: result)
                }
            }
            html = rendered
            isLoading = false
            updateFindAvailability()
        } catch {
            isLoading = false
            errorMessage = "Failed to read file: \(error.localizedDescription)"
            updateFindAvailability()
        }
    }

    private func handleFindMenuRequest(_ request: FindMenuRequest) {
        switch request.command {
        case .none:
            break
        case .showFindInterface:
            openFind()
        case .nextMatch:
            nextMatch()
        case .previousMatch:
            previousMatch()
        case .hideFindInterface:
            closeFind()
        }
    }

    private func openFind() {
        guard html != nil else {
            updateFindAvailability()
            return
        }

        isFindBarVisible = true
        findFocusRequestID += 1
        updateFindAvailability()
        search(findQuery)
    }

    private func closeFind() {
        guard isFindBarVisible || findResult != .empty else { return }

        isFindBarVisible = false
        findResult = .empty
        updateFindAvailability()
        issueFindAction(.clear)
    }

    private func search(_ query: String) {
        guard isFindBarVisible, html != nil else { return }

        updateFindAvailability()
        issueFindAction(.search(query))
    }

    private func nextMatch() {
        if !isFindBarVisible {
            openFind()
            return
        }

        guard !findQuery.isEmpty else { return }
        issueFindAction(.next)
    }

    private func previousMatch() {
        if !isFindBarVisible {
            openFind()
            return
        }

        guard !findQuery.isEmpty else { return }
        issueFindAction(.previous)
    }

    private func handleFindResult(_ result: FindResult) {
        guard result.query.isEmpty || (isFindBarVisible && result.query == findQuery) else {
            return
        }

        findResult = result
        updateFindAvailability()
    }

    private func issueFindAction(_ action: FindAction) {
        findRequestID += 1
        findRequest = FindRequest(id: findRequestID, action: action)
    }

    private func updateFindAvailability() {
        findCommandBridge.updateAvailability(
            canFind: html != nil,
            isFindVisible: isFindBarVisible,
            hasQuery: isFindBarVisible && !findQuery.isEmpty
        )
    }
}
