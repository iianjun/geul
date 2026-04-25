import AppKit

final class PopupWindow: NSPanel {
    private static let autosaveName = NSWindow.FrameAutosaveName("geul.popupWindowFrame")

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 400),
            styleMask: [.hudWindow, .nonactivatingPanel, .titled, .closable],
            backing: .buffered,
            defer: false
        )
        self.contentView = contentView
        self.isFloatingPanel = true
        self.level = .floating
        self.hidesOnDeactivate = true
        self.isMovableByWindowBackground = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.setFrameAutosaveName(Self.autosaveName)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func restoreSavedPositionOrCenter() {
        if !setFrameUsingName(Self.autosaveName) {
            center()
        }
    }
}
