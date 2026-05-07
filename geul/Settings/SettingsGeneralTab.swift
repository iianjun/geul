import AppKit
import ServiceManagement
import SwiftUI

struct SettingsGeneralTab: View {
    @ObservedObject private var store: SettingsStore = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Launch at login", isOn: Binding(
                get: { store.settings.launchAtLogin },
                set: { applyLaunchAtLogin($0) }
            ))

            Stepper(
                "Recent files to show: \(store.settings.recentFilesCount)",
                value: Binding(
                    get: { store.settings.recentFilesCount },
                    set: { newValue in
                        store.update { $0.recentFilesCount = newValue }
                    }
                ),
                in: 0...50
            )

            Spacer()
        }
        .padding(16)
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            store.update { $0.launchAtLogin = enabled }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to \(enabled ? "enable" : "disable") launch at login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            store.update { $0.launchAtLogin = !enabled }
        }
    }
}
