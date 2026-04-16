import SwiftUI

struct ContentView: View {
    let fileURL: URL?
    @State private var html: String?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if let html {
                MarkdownWebView(html: html, fileURL: fileURL)
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
            let rendered = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    let body = MarkdownRenderer.render(markdown)
                    let result = HTMLTemplate.compose(body: body, title: title)
                    continuation.resume(returning: result)
                }
            }
            html = rendered
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }
}
