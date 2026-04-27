import AppKit
import SwiftUI

struct PopupView: View {
    @ObservedObject private var index: FileIndex = .shared
    @ObservedObject private var recents: RecentFilesStore = .shared
    @ObservedObject private var themeStore: ThemeStore = .shared
    @State private var query: String = ""
    @State private var selection: Int = 0
    @State private var keyMonitor: Any?
    @FocusState private var searchFocused: Bool

    var onSelect: (URL) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $query, focused: $searchFocused)
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
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
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

    private func moveSelection(_ delta: Int) {
        guard hasItems else { return }
        let count = itemCount
        selection = (selection + delta + count) % count
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

    /// SwiftUI's TextField captures up/down arrows and Enter when focused.
    /// A local NSEvent monitor lets us catch the navigation/submit/dismiss
    /// keys at the app level before the field consumes them, then return
    /// nil to swallow. Other keys pass through unchanged.
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 126: // up arrow
                moveSelection(-1)
                return nil
            case 125: // down arrow
                moveSelection(1)
                return nil
            case 36, 76: // return / numpad enter
                submit()
                return nil
            case 53: // escape
                onDismiss()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

private struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search .md files", text: $text)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused(focused)
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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, entry in
                            let url = URL(fileURLWithPath: entry.path)
                            ResultRow(
                                title: url.lastPathComponent,
                                subtitle: entry.path,
                                isSelected: idx == selection
                            )
                            .id(idx)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(entry.path) }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: selection) { _, newValue in
                    withAnimation(.linear(duration: 0.08)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, file in
                            ResultRow(
                                title: file.name,
                                subtitle: file.url.path,
                                isSelected: idx == selection
                            )
                            .id(idx)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(file.url) }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: selection) { _, newValue in
                    withAnimation(.linear(duration: 0.08)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }
}

private struct ResultRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: "doc.text")
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.clear)
        .foregroundStyle(isSelected ? Color.white : Color.primary)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
