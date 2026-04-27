import AppKit
import SwiftUI

@MainActor
final class MenubarController {
    private(set) static weak var shared: MenubarController?

    private var statusItem: NSStatusItem?
    private var popup: PopupWindow?

    init() {
        MenubarController.shared = self
    }

    func install() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "doc.text",
                accessibilityDescription: "geul"
            )
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    func uninstall() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        popup?.close()
        popup = nil
    }

    func showPopup() {
        let view = PopupView(
            onSelect: { [weak self] url in
                guard let self else { return }
                self.hidePopup()
                RecentFilesStore.shared.bump(url)
                AppDelegate.shared?.openWindow(for: url)
            },
            onDismiss: { [weak self] in
                self?.hidePopup()
            }
        )
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 640, height: 400)

        if let existing = popup {
            existing.contentView = hosting
        } else {
            popup = PopupWindow(contentView: hosting)
        }
        guard let popup else { return }
        popup.restoreSavedPositionOrCenter()
        // .nonactivatingPanel: panel itself doesn't activate the app.
        // Without this, the popup can stay below the active app's windows.
        NSApp.activate(ignoringOtherApps: true)
        popup.orderFrontRegardless()
        popup.makeKey()
    }

    func hidePopup() {
        popup?.orderOut(nil)
    }

    func togglePopup() {
        if popup?.isVisible == true {
            hidePopup()
        } else {
            showPopup()
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp ||
            event?.modifierFlags.contains(.option) == true {
            showDropdown()
        } else {
            togglePopup()
        }
    }

    private func showDropdown() {
        let menu = NSMenu()
        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: "Quit geul",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openSettings() {
        // Activate so the SwiftUI Settings scene actually surfaces; without
        // this, sendAction can succeed but the window stays behind other apps.
        NSApp.activate(ignoringOtherApps: true)
        // Defer one runloop tick so this fires after the dropdown menu has
        // fully dismissed. Sending while the menu is mid-tear-down leaves the
        // responder chain in a state where neither showSettingsWindow:
        // nor showPreferencesWindow: lands.
        DispatchQueue.main.async {
            if #available(macOS 14, *) {
                if NSApp.sendAction(
                    Selector(("showSettingsWindow:")), to: nil, from: nil) {
                    return
                }
            }
            if NSApp.sendAction(
                Selector(("showPreferencesWindow:")), to: nil, from: nil) {
                return
            }
            // Last resort: invoke the auto-generated app-menu Settings item
            // directly. That's the same item ⌘, fires.
            Self.invokeAppMenuSettingsItem()
        }
    }

    private static func invokeAppMenuSettingsItem() {
        guard let appMenu = NSApp.mainMenu?.item(at: 0)?.submenu else { return }
        for item in appMenu.items where item.keyEquivalent == "," {
            guard let action = item.action else { return }
            NSApp.sendAction(action, to: item.target, from: item)
            return
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
