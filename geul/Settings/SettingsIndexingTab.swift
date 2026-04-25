import AppKit
import SwiftUI

struct SettingsIndexingTab: View {
    @ObservedObject private var store: SettingsStore = .shared
    @ObservedObject private var index: FileIndex = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Indexing roots")
                .font(.headline)
            Text("geul scans these folders for .md files.")
                .font(.caption).foregroundStyle(.secondary)

            List {
                ForEach(store.settings.indexRoots, id: \.self) { path in
                    HStack {
                        Image(systemName: "folder")
                        Text(path).lineLimit(1).truncationMode(.middle)
                        if !FileManager.default.fileExists(atPath: path) {
                            Text("⚠ Access denied")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        Button {
                            remove(path)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button("+ Add folder…") { addFolder() }
                Spacer()
                Button("Rescan now") {
                    index.rescan(roots: store.indexRootsURLs)
                }
            }

            Divider()

            HStack(spacing: 6) {
                if index.isScanning {
                    ProgressView().controlSize(.small)
                    Text("Indexing \(index.files.count) files…").font(.caption)
                } else {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("Indexed \(index.files.count) files").font(.caption)
                }
                Spacer()
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(16)
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"
        if panel.runModal() == .OK, let url = panel.url {
            let path = url.standardizedFileURL.path
            guard !store.settings.indexRoots.contains(path) else { return }
            store.update { $0.indexRoots.append(path) }
            index.rescan(roots: store.indexRootsURLs)
        }
    }

    private func remove(_ path: String) {
        store.update { $0.indexRoots.removeAll { $0 == path } }
        index.rescan(roots: store.indexRootsURLs)
    }
}
