import AppKit
import ServiceManagement
import SwiftUI

@MainActor
final class OnboardingWindow {
    private var window: NSWindow?

    static let markerFilename = ".onboarded"

    var markerURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/geul")
            .appendingPathComponent(Self.markerFilename)
    }

    var hasOnboarded: Bool {
        FileManager.default.fileExists(atPath: markerURL.path)
    }

    func showIfNeeded() {
        guard !hasOnboarded else { return }
        let view = OnboardingView(
            onDone: { [weak self] launchAtLogin in
                if launchAtLogin {
                    try? SMAppService.mainApp.register()
                    SettingsStore.shared.update { $0.launchAtLogin = true }
                }
                self?.markDone()
                self?.close()
            },
            onSetShortcut: { [weak self] in
                self?.close()
                SettingsNavigator.shared.request(.shortcuts)
                NSApp.sendAction(
                    Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        )
        let hosting = NSHostingView(rootView: view)
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.contentView = hosting
        win.title = "Welcome to geul"
        win.center()
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        window = win
    }

    private func markDone() {
        try? FileManager.default.createDirectory(
            at: markerURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try? Data().write(to: markerURL)
    }

    private func close() {
        window?.close()
        window = nil
    }
}
