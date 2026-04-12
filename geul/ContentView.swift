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
                MarkdownWebView(html: html)
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
            let htmlBody = MarkdownRenderer.render(markdown)
            html = HTMLTemplate.compose(body: htmlBody, title: fileURL.lastPathComponent)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }
}
