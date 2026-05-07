import AppKit
import SwiftUI

struct ContentView: View {
    let fileURL: URL?
    @StateObject private var themeStore = ThemeStore.shared
    @State private var html: String?
    @State private var markdown: String?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var didCopyMarkdown = false
    @State private var copyFeedbackTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if let html {
                MarkdownWebView(
                    html: html,
                    fileURL: fileURL,
                    theme: themeStore.resolved,
                    onMarkdownReload: { reloadedMarkdown in
                        markdown = reloadedMarkdown
                    }
                )
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
            TitlebarCopyButton(
                isVisible: markdown != nil,
                didCopyMarkdown: didCopyMarkdown,
                action: copyMarkdown
            )
            .frame(width: 0, height: 0)
        )
        .animation(.easeInOut(duration: 0.2), value: isLoading)
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
            return
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            markdown = nil
            isLoading = false
            errorMessage = "File not found: \(fileURL.path)"
            return
        }

        do {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            let title = fileURL.lastPathComponent
            let theme = themeStore.resolved
            let rendered = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    let body = MarkdownRenderer.render(source)
                    let result = HTMLTemplate.compose(
                        body: body,
                        title: title,
                        theme: theme
                    )
                    continuation.resume(returning: result)
                }
            }
            markdown = source
            html = rendered
            isLoading = false
        } catch {
            markdown = nil
            isLoading = false
            errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
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

private struct TitlebarCopyButton: NSViewRepresentable {
    let isVisible: Bool
    let didCopyMarkdown: Bool
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
        context.coordinator.state = State(isVisible: isVisible, didCopyMarkdown: didCopyMarkdown)

        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: nsView)
            context.coordinator.applyState()
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    struct State {
        let isVisible: Bool
        let didCopyMarkdown: Bool
    }

    final class Coordinator: NSObject {
        var action: () -> Void = {}
        var state = State(isVisible: false, didCopyMarkdown: false)
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

            let button = NSButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.isBordered = false
            button.title = ""
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.setButtonType(.momentaryPushIn)
            button.target = self
            button.action = #selector(copyMarkdown)

            titlebarView.addSubview(button)
            constraints = [
                button.trailingAnchor.constraint(equalTo: titlebarView.trailingAnchor, constant: -16),
                button.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 16),
                button.heightAnchor.constraint(equalToConstant: 16)
            ]
            NSLayoutConstraint.activate(constraints)

            self.button = button
            installedWindow = window
            applyState()
        }

        func applyState() {
            guard let button else { return }

            let title = state.didCopyMarkdown ? "Copied" : "Copy Markdown"
            let symbolName = state.didCopyMarkdown ? "checkmark" : "doc.on.doc"
            let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)?
                .withSymbolConfiguration(configuration)

            image?.size = NSSize(width: 12, height: 12)
            button.image = image
            button.toolTip = title
            button.isHidden = !state.isVisible
            button.isEnabled = state.isVisible
            button.setAccessibilityLabel(title)
        }

        func uninstall() {
            NSLayoutConstraint.deactivate(constraints)
            constraints.removeAll()
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
