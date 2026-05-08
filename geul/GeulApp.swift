import SwiftUI

enum DockVisibilityPolicy {
    static func launchActivationPolicy(
        launchedFromCLIWrapper: Bool
    ) -> NSApplication.ActivationPolicy {
        launchedFromCLIWrapper ? .regular : .accessory
    }

    static var readerWindowOpenedPolicy: NSApplication.ActivationPolicy {
        .regular
    }

    static func readerWindowsDidChangePolicy(
        isAgentMode: Bool,
        readerWindowCount: Int
    ) -> NSApplication.ActivationPolicy? {
        guard isAgentMode, readerWindowCount == 0 else { return nil }
        return .accessory
    }
}

struct GeulApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(after: .textEditing) {
                Divider()

                Button("Find...") {
                    AppDelegate.performFindCommand(
                        tag: NSTextFinder.Action.showFindInterface.rawValue
                    )
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find Next") {
                    AppDelegate.performFindCommand(
                        tag: NSTextFinder.Action.nextMatch.rawValue
                    )
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    AppDelegate.performFindCommand(
                        tag: NSTextFinder.Action.previousMatch.rawValue
                    )
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }
        }
    }
}

enum ReaderWindowSizing {
    static let defaultContentSize = NSSize(width: 900, height: 700)
    static let minimumContentSize = NSSize(width: 500, height: 300)

    static func defaultContentRect(origin: NSPoint = .zero) -> NSRect {
        NSRect(origin: origin, size: defaultContentSize)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation {
    private static let cliLaunchMarker = "--geul-opened-by-cli"

    private(set) static weak var shared: AppDelegate?

    private(set) var windows: [NSWindow] = []
    private(set) var isAgentMode = false
    private var pendingAgentEntry: DispatchWorkItem?
    private var receivedOpenURLs = false
    private let launchedFromCLIWrapper: Bool
    private var menubar: MenubarController?
    private let onboarding = OnboardingWindow()

    override init() {
        self.launchedFromCLIWrapper = CommandLine.arguments.contains(Self.cliLaunchMarker)
        super.init()
        AppDelegate.shared = self
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !isAgentMode
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        applyActivationPolicy(
            DockVisibilityPolicy.launchActivationPolicy(
                launchedFromCLIWrapper: launchedFromCLIWrapper
            )
        )
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
        return true
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        windows.removeAll { $0 === window }
        if let policy = DockVisibilityPolicy.readerWindowsDidChangePolicy(
            isAgentMode: isAgentMode,
            readerWindowCount: windows.count
        ) {
            applyActivationPolicy(policy)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        receivedOpenURLs = true
        pendingAgentEntry?.cancel()
        pendingAgentEntry = nil
        for url in urls {
            openWindow(for: url)
        }
    }

    @objc func performTextFinderAction(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else { return }

        Self.performFindCommand(tag: menuItem.tag)
    }

    static func performFindCommand(tag: Int) {
        guard let window = activeMarkdownWindow else { return }
        let menuItem = NSMenuItem(
            title: "",
            action: #selector(NSResponder.performTextFinderAction(_:)),
            keyEquivalent: ""
        )
        menuItem.tag = tag

        NSApp.sendAction(
            #selector(NSResponder.performTextFinderAction(_:)),
            to: window,
            from: menuItem
        )
    }

    private static var activeMarkdownWindow: MarkdownWindow? {
        NSApp.keyWindow as? MarkdownWindow
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(performTextFinderAction(_:)) {
            return Self.activeMarkdownWindow?.validateFindCommand(tag: menuItem.tag) ?? false
        }

        return true
    }

    func openWindow(for fileURL: URL?) {
        applyActivationPolicy(DockVisibilityPolicy.readerWindowOpenedPolicy)
        let window = Self.makeReaderWindow(for: fileURL)
        window.delegate = self
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        windows.append(window)

        if let fileURL {
            RecentFilesStore.shared.bump(fileURL)
        }
    }

    static func makeReaderWindow(for fileURL: URL?) -> MarkdownWindow {
        let findCommandBridge = FindCommandBridge()
        let window = MarkdownWindow(
            findCommandBridge: findCommandBridge,
            contentRect: ReaderWindowSizing.defaultContentRect(),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentMinSize = ReaderWindowSizing.minimumContentSize
        window.contentViewController = NSHostingController(
            rootView: ContentView(
                fileURL: fileURL,
                findCommandBridge: findCommandBridge
            )
                .frame(
                    minWidth: ReaderWindowSizing.minimumContentSize.width,
                    minHeight: ReaderWindowSizing.minimumContentSize.height
                )
        )
        window.setContentSize(ReaderWindowSizing.defaultContentSize)
        window.title = fileURL?.lastPathComponent ?? "geul"
        return window
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
        onboarding.showIfNeeded()
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

    private func applyActivationPolicy(
        _ policy: NSApplication.ActivationPolicy
    ) {
        NSApp.setActivationPolicy(policy)
    }
}
