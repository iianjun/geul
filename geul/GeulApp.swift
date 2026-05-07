import SwiftUI

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

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation {
    private var windows: [MarkdownWindow] = []

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        // Apple Events(open:)가 didFinishLaunching 전에 호출됨
        // 파일 없이 실행된 경우 usage 창 표시
        DispatchQueue.main.async { [self] in
            if windows.isEmpty {
                openWindow(for: nil)
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? MarkdownWindow else { return }
        windows.removeAll { $0 === window }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
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

    private func openWindow(for fileURL: URL?) {
        let findCommandBridge = FindCommandBridge()
        let window = MarkdownWindow(
            findCommandBridge: findCommandBridge,
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: ContentView(
                fileURL: fileURL,
                findCommandBridge: findCommandBridge
            )
                .frame(minWidth: 500, minHeight: 300)
        )
        window.title = fileURL?.lastPathComponent ?? "geul"
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
}
