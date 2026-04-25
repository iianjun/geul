import SwiftUI

struct GeulApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static let cliLaunchMarker = "--geul-opened-by-cli"

    private(set) static weak var shared: AppDelegate?

    private(set) var windows: [NSWindow] = []
    private(set) var isAgentMode = false
    private var pendingAgentEntry: DispatchWorkItem?
    private var receivedOpenURLs = false
    private let launchedFromCLIWrapper: Bool
    private var menubar: MenubarController?

    override init() {
        self.launchedFromCLIWrapper = CommandLine.arguments.contains(Self.cliLaunchMarker)
        super.init()
        AppDelegate.shared = self
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !isAgentMode
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if launchedFromCLIWrapper {
            scheduleCLIWrapperFallbackTermination()
            return
        }

        // LaunchServices may deliver open-file Apple Events around launch time.
        // Defer Agent-mode entry briefly and cancel it if `application(_:open:)`
        // receives URLs. This preserves lightweight CLI/Finder-open behavior
        // instead of accidentally installing the resident agent.
        let work = DispatchWorkItem { [weak self] in
            guard let self,
                  self.windows.isEmpty,
                  !self.receivedOpenURLs else { return }
            self.enterAgentMode()
        }
        pendingAgentEntry = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    func applicationWillTerminate(_ notification: Notification) {
        RecentFilesStore.shared.flush()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows flag: Bool
    ) -> Bool {
        if isAgentMode && !flag {
            MenubarController.shared?.showPopup()
            return false
        }
        return true
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        windows.removeAll { $0 === window }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        receivedOpenURLs = true
        pendingAgentEntry?.cancel()
        pendingAgentEntry = nil
        for url in urls {
            openWindow(for: url)
        }
    }

    func openWindow(for fileURL: URL?) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: ContentView(fileURL: fileURL)
                .frame(minWidth: 500, minHeight: 300)
        )
        window.title = fileURL?.lastPathComponent ?? "geul"
        window.delegate = self
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        windows.append(window)

        if let fileURL {
            RecentFilesStore.shared.bump(fileURL)
        }
    }

    // MARK: - Agent mode

    private func enterAgentMode() {
        guard !isAgentMode else { return }
        pendingAgentEntry?.cancel()
        pendingAgentEntry = nil
        isAgentMode = true
        let controller = MenubarController()
        controller.install()
        menubar = controller
        HotkeyRegistrar.shared.wireIfEnabled()
        let roots = SettingsStore.shared.indexRootsURLs
        FileIndex.shared.bootstrap(roots: roots)
    }

    private func scheduleCLIWrapperFallbackTermination() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self,
                  !self.isAgentMode,
                  self.windows.isEmpty,
                  !self.receivedOpenURLs else { return }
            NSApp.terminate(nil)
        }
    }
}
