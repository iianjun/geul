import SwiftUI

@main
struct GeulApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var windows: [NSWindow] = []

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

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        windows.removeAll { $0 === window }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            openWindow(for: url)
        }
    }

    private func openWindow(for fileURL: URL?) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(
            rootView: ContentView(fileURL: fileURL)
                .frame(minWidth: 500, minHeight: 300)
        )
        window.title = fileURL?.lastPathComponent ?? "geul"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
}
