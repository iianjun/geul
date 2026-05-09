import AppKit
import SwiftUI

struct ContentView: View {
    let fileURL: URL?
    @ObservedObject var readerWindowState: ReaderWindowState
    @ObservedObject var findCommandBridge: FindCommandBridge
    @StateObject private var themeStore = ThemeStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var html: String?
    @State private var markdown: String?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var didCopyMarkdown = false
    @State private var copyFeedbackTask: Task<Void, Never>?
    @State private var isFindBarVisible = false
    @State private var findQuery = ""
    @State private var findRequest = FindRequest.initial
    @State private var findRequestID = FindRequest.initial.id
    @State private var findResult = FindResult.empty
    @State private var findFocusRequestID = 0

    init(
        fileURL: URL?,
        readerWindowState: ReaderWindowState,
        findCommandBridge: FindCommandBridge = FindCommandBridge()
    ) {
        self.fileURL = fileURL
        self.readerWindowState = readerWindowState
        self.findCommandBridge = findCommandBridge
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if let html {
                MarkdownWebView(
                    html: html,
                    fileURL: fileURL,
                    theme: themeStore.resolved,
                    readerAlignment: settingsStore.settings.readerAlignment,
                    findRequest: findRequest,
                    onFindResult: handleFindResult,
                    onMarkdownReload: { reloadedMarkdown in
                        markdown = reloadedMarkdown
                    }
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
        .background(
            TitlebarReaderControls(
                isCopyVisible: markdown != nil,
                didCopyMarkdown: didCopyMarkdown,
                zoomPercent: readerWindowState.zoomPercent,
                action: copyMarkdown
            )
            .frame(width: 0, height: 0)
        )
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
        .onDisappear {
            copyFeedbackTask?.cancel()
        }
    }

    private func loadFile() async {
        guard let fileURL else {
            markdown = nil
            isLoading = false
            errorMessage = "Usage: geul <file.md>"
            updateFindAvailability()
            return
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            markdown = nil
            isLoading = false
            errorMessage = "File not found: \(fileURL.path)"
            updateFindAvailability()
            return
        }

        do {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            let title = fileURL.lastPathComponent
            let theme = themeStore.resolved
            let readerAlignment = settingsStore.settings.readerAlignment
            let rendered = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    let body = MarkdownRenderer.render(source)
                    let result = HTMLTemplate.compose(
                        body: body,
                        title: title,
                        theme: theme,
                        readerAlignment: readerAlignment
                    )
                    continuation.resume(returning: result)
                }
            }
            markdown = source
            html = rendered
            isLoading = false
            updateFindAvailability()
        } catch {
            markdown = nil
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

    private func copyMarkdown() {
        guard let markdown else { return }
        guard MarkdownClipboard.copy(markdown) else { return }

        copyFeedbackTask?.cancel()
        didCopyMarkdown = true
        copyFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                didCopyMarkdown = false
            }
        }
    }
}

private struct TitlebarReaderControls: NSViewRepresentable {
    let isCopyVisible: Bool
    let didCopyMarkdown: Bool
    let zoomPercent: Int
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.action = action
        context.coordinator.state = State(
            isCopyVisible: isCopyVisible,
            didCopyMarkdown: didCopyMarkdown,
            zoomPercent: zoomPercent
        )

        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: nsView)
            context.coordinator.applyState()
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    struct State {
        let isCopyVisible: Bool
        let didCopyMarkdown: Bool
        let zoomPercent: Int
    }

    final class Coordinator: NSObject {
        var action: () -> Void = {}
        var state = State(isCopyVisible: false, didCopyMarkdown: false, zoomPercent: 100)
        private weak var zoomLabel: NSTextField?
        private weak var button: NSButton?
        private weak var installedWindow: NSWindow?
        private var constraints: [NSLayoutConstraint] = []

        func installIfNeeded(from hostView: NSView) {
            guard let window = hostView.window else { return }
            guard button == nil || installedWindow !== window else { return }

            uninstall()

            guard
                let closeButton = window.standardWindowButton(.closeButton),
                let titlebarView = closeButton.superview
            else {
                return
            }

            let zoomLabel = NSTextField(labelWithString: "")
            zoomLabel.translatesAutoresizingMaskIntoConstraints = false
            zoomLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
            zoomLabel.textColor = .secondaryLabelColor
            zoomLabel.alignment = .right
            zoomLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            let button = NSButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.isBordered = false
            button.title = ""
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.setButtonType(.momentaryPushIn)
            button.target = self
            button.action = #selector(copyMarkdown)

            titlebarView.addSubview(zoomLabel)
            titlebarView.addSubview(button)
            constraints = [
                button.trailingAnchor.constraint(equalTo: titlebarView.trailingAnchor, constant: -16),
                button.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 16),
                button.heightAnchor.constraint(equalToConstant: 16),
                zoomLabel.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -10),
                zoomLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
                zoomLabel.widthAnchor.constraint(equalToConstant: 42)
            ]
            NSLayoutConstraint.activate(constraints)

            self.zoomLabel = zoomLabel
            self.button = button
            installedWindow = window
            applyState()
        }

        func applyState() {
            zoomLabel?.stringValue = "\(state.zoomPercent)%"
            zoomLabel?.toolTip = "Zoom \(state.zoomPercent)%"
            zoomLabel?.setAccessibilityLabel("Zoom \(state.zoomPercent)%")

            guard let button else { return }

            let title = state.didCopyMarkdown ? "Copied" : "Copy Markdown"
            let symbolName = state.didCopyMarkdown ? "checkmark" : "doc.on.doc"
            let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)?
                .withSymbolConfiguration(configuration)

            image?.size = NSSize(width: 12, height: 12)
            button.image = image
            button.toolTip = title
            button.isHidden = !state.isCopyVisible
            button.isEnabled = state.isCopyVisible
            button.setAccessibilityLabel(title)
        }

        func uninstall() {
            NSLayoutConstraint.deactivate(constraints)
            constraints.removeAll()
            zoomLabel?.removeFromSuperview()
            zoomLabel = nil
            button?.removeFromSuperview()
            button = nil
            installedWindow = nil
        }

        @objc private func copyMarkdown() {
            action()
        }
    }
}

enum MarkdownClipboard {
    @discardableResult
    static func copy(_ markdown: String, pasteboard: NSPasteboard = .general) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(markdown, forType: .string)
    }
}
