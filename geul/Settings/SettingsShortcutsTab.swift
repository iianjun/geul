import KeyboardShortcuts
import SwiftUI

struct SettingsShortcutsTab: View {
    @ObservedObject private var store: SettingsStore = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Global Shortcut").font(.headline)

            Toggle("Enable global hotkey", isOn: Binding(
                get: { store.settings.hotkey.enabled },
                set: { enabled in
                    store.update { $0.hotkey.enabled = enabled }
                    HotkeyRegistrar.shared.wireIfEnabled()
                }
            ))

            KeyboardShortcuts.Recorder("Open popup:", name: .openPopup)
                .disabled(!store.settings.hotkey.enabled)

            Text("핫키를 꺼도 메뉴바 또는 Dock 아이콘 클릭으로 팝업을 열 수 있어요.")
                .font(.caption).foregroundStyle(.secondary)

            Spacer()
        }
        .padding(16)
    }
}
