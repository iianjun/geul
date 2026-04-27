import AppKit

final class PopupWindow: NSPanel {
    private static let autosaveName = NSWindow.FrameAutosaveName("geul.popupWindowFrame")

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 400),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // ARC manages lifetime via MenubarController.popup; opt out of
        // NSWindow's auto-release-on-close.
        self.isReleasedWhenClosed = false
        self.animationBehavior = .none
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
