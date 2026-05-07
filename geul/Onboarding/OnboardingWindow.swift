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
                // Order: tab first → activate app → open Settings → close
                // onboarding on the next runloop tick. Closing the active
                // window before sendAction can leave AppKit without a key
                // window during the transition.
                SettingsNavigator.shared.request(.shortcuts)
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(
                    Selector(("showSettingsWindow:")), to: nil, from: nil)
                DispatchQueue.main.async { [weak self] in
                    self?.close()
                }
            }
        )
        let hosting = NSHostingView(rootView: view)
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        // We own the lifecycle through `window`; let ARC release it instead
        // of NSWindow's auto-release-on-close, which double-releases under
        // CoreAnimation cleanup on macOS 26.
        win.isReleasedWhenClosed = false
        // Disable transform animation entirely — Set-shortcut path closes
        // this window while opening Settings, and the overlapping animation
        // dealloc was crashing in -[_NSWindowTransformAnimation dealloc].
        win.animationBehavior = .none
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
        // orderOut bypasses the close cycle (no will-close notifications,
        // no transform animation). With isReleasedWhenClosed = false set
        // in showIfNeeded, ARC handles lifetime once we drop the ref.
        window?.orderOut(nil)
        window = nil
    }
}
