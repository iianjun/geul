import AppKit
import SwiftUI

struct SettingsView: View {
    enum Tab: Hashable {
        case themes, indexing, shortcuts, general
    }

    @ObservedObject private var navigator = SettingsNavigator.shared

    var body: some View {
        TabView(selection: $navigator.requestedTab) {
            SettingsThemesTab()
                .tabItem { Label("Themes", systemImage: "paintpalette") }
                .tag(Tab.themes)
            SettingsIndexingTab()
                .tabItem { Label("Indexing", systemImage: "folder") }
                .tag(Tab.indexing)
            SettingsShortcutsTab()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(Tab.shortcuts)
            SettingsGeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tab.general)
        }
        .frame(width: 520, height: 440)
        .background(WindowTitleSetter(title: "Settings"))
    }
}

/// Overrides the system-assigned "<AppName> Settings" window title.
private struct WindowTitleSetter: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            view?.window?.title = title
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            nsView?.window?.title = title
        }
    }
}
