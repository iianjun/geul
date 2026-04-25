import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openPopup = Self("geul.openPopup")
}

@MainActor
final class HotkeyRegistrar {
    static let shared = HotkeyRegistrar()
    private var handlerRegistered = false

    /// Enables the global hotkey if settings opt-in. Idempotent — safe to call
    /// on every settings change or on wake.
    ///
    /// Implementation notes:
    /// - `KeyboardShortcuts.onKeyDown(for:)` appends to an internal handler
    ///   list, so we gate it behind `handlerRegistered` to avoid duplicate fires.
    /// - Toggling off uses `disable(.openPopup)` rather than
    ///   `removeAllHandlers()`: it preserves the recorded shortcut + the
    ///   registered closure, so flipping back on is a single
    ///   `enable(.openPopup)` call with no re-registration. It's also surgical
    ///   (only affects `.openPopup`), so future additional hotkeys won't be
    ///   collaterally cleared.
    func wireIfEnabled() {
        let enabled = SettingsStore.shared.settings.hotkey.enabled
        if !handlerRegistered {
            KeyboardShortcuts.onKeyDown(for: .openPopup) {
                MenubarController.shared?.togglePopup()
            }
            handlerRegistered = true
        }
        if enabled {
            KeyboardShortcuts.enable(.openPopup)
        } else {
            KeyboardShortcuts.disable(.openPopup)
        }
    }

    /// Explicit disable entry point for callers that want "off" without
    /// consulting settings (e.g. a future pause-mode).
    func unwire() {
        guard handlerRegistered else { return }
        KeyboardShortcuts.disable(.openPopup)
    }
}
