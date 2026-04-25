import SwiftUI

struct PopupView: View {
    @ObservedObject private var index: FileIndex = .shared
    @ObservedObject private var recents: RecentFilesStore = .shared
    @ObservedObject private var themeStore: ThemeStore = .shared
    @State private var query: String = ""
    @State private var selection: Int = 0
    @FocusState private var searchFocused: Bool

    var onSelect: (URL) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $query, onSubmit: submit, focused: $searchFocused)
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            resultsSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if index.isScanning {
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Indexing \(index.files.count) files…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(8)
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .frame(width: 640, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: query) { _, _ in selection = 0 }
        .onAppear {
            DispatchQueue.main.async { searchFocused = true }
        }
        .onKeyPress(.upArrow) { moveSelection(-1) }
        .onKeyPress(.downArrow) { moveSelection(1) }
        .onKeyPress(.escape) { onDismiss(); return .handled }
        .onKeyPress(.return) { submit(); return .handled }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if query.isEmpty {
            RecentList(
                items: recents.items,
                selection: selection,
                onSelect: { onSelect(URL(fileURLWithPath: $0)) }
            )
        } else {
            ResultList(
                items: index.search(query, limit: 50),
                selection: selection,
                onSelect: { onSelect($0) }
            )
        }
    }

    private var itemCount: Int {
        query.isEmpty ? recents.items.count : index.search(query, limit: 50).count
    }

    private var hasItems: Bool {
        query.isEmpty ? !recents.items.isEmpty : !index.search(query, limit: 50).isEmpty
    }

    private func moveSelection(_ delta: Int) -> KeyPress.Result {
        guard hasItems else { return .handled }
        let count = itemCount
        selection = (selection + delta + count) % count
        return .handled
    }

    private func submit() {
        if query.isEmpty {
            if let entry = recents.items[safe: selection] {
                onSelect(URL(fileURLWithPath: entry.path))
            }
        } else {
            let results = index.search(query, limit: 50)
            if let file = results[safe: selection] {
                onSelect(file.url)
            }
        }
    }
}

private struct SearchField: View {
    @Binding var text: String
    var onSubmit: () -> Void
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search .md files", text: $text)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused(focused)
                .onSubmit(onSubmit)
        }
    }
}

private struct RecentList: View {
    let items: [RecentEntry]
    let selection: Int
    var onSelect: (String) -> Void

    var body: some View {
        if items.isEmpty {
            placeholder
        } else {
            List {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, entry in
                    let url = URL(fileURLWithPath: entry.path)
                    row(
                        title: url.lastPathComponent,
                        subtitle: entry.path,
                        isSelected: idx == selection
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(entry.path) }
                }
            }
            .listStyle(.plain)
        }
    }

    private var placeholder: some View {
        VStack(spacing: 6) {
            Text("Type to search your markdown files")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Or open them from the terminal to populate recent list")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(title: String, subtitle: String, isSelected: Bool) -> some View {
        HStack {
            Image(systemName: "doc.text")
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .listRowBackground(
            isSelected ? Color.accentColor.opacity(0.2) : Color.clear
        )
    }
}

private struct ResultList: View {
    let items: [IndexedFile]
    let selection: Int
    var onSelect: (URL) -> Void

    var body: some View {
        if items.isEmpty {
            VStack {
                Text("No matches")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, file in
                    HStack {
                        Image(systemName: "doc.text")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name).font(.body)
                            Text(file.url.path)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(
                        idx == selection ? Color.accentColor.opacity(0.2) : Color.clear
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(file.url) }
                }
            }
            .listStyle(.plain)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
