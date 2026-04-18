import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var store = ThemeStore.shared
    @State private var errorMessage: String?
    @State private var pendingDelete: LoadedTheme?

    var body: some View {
        Form {
            Section {
                ForEach(store.themes) { loaded in
                    ThemeRow(
                        theme: loaded,
                        isSelected: loaded.name == store.selectedName,
                        onSelect: { store.select(name: loaded.name) },
                        onDelete: { pendingDelete = loaded }
                    )
                }

                HStack {
                    Button("Reload") { store.reload() }
                    Spacer()
                    Button("Import Theme…", action: importTheme)
                        .keyboardShortcut("i", modifiers: [.command])
                        .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            } header: {
                Text("Themes")
            }

            Section {
                HStack {
                    Text("~/.config/geul/themes/")
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Button("Reveal in Finder") {
                        store.revealThemesFolder()
                    }
                }
            } header: {
                Text("Themes folder")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 360)
        .alert("Import failed", isPresented: errorBinding, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { message in
            Text(message)
        }
        .alert("Remove \(pendingDelete?.name ?? "")?",
               isPresented: deleteBinding,
               presenting: pendingDelete) { loaded in
            Button("Remove", role: .destructive) {
                store.removeUserTheme(name: loaded.name)
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { _ in
            Text("This deletes the theme file from ~/.config/geul/themes/.")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func importTheme() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        panel.prompt = "Import"
        panel.message = "Select a geul theme JSON file"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try store.importTheme(from: url)
        } catch {
            errorMessage = "Couldn't import \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }
}

private struct ThemeRow: View {
    let theme: LoadedTheme
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .font(.system(size: 16))

            Text(theme.name)
                .font(.body)

            Spacer()

            Text(theme.isBuiltIn ? "Built-in" : "User")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(
                    theme.isBuiltIn
                        ? Color.secondary.opacity(0.15)
                        : Color.accentColor.opacity(0.18)
                )
                .foregroundStyle(theme.isBuiltIn ? Color.secondary : Color.accentColor)
                .clipShape(Capsule())

            if !theme.isBuiltIn {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove theme")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}
