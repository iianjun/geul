import AppKit
import XCTest
@testable import geul

@MainActor
final class MenubarControllerPopupTests: XCTestCase {
    func testToggleShowsPopupAfterAppDeactivationDismissesIt() {
        let controller = MenubarController()
        controller.showPopup()
        defer { controller.uninstall() }

        XCTAssertEqual(Self.visiblePopupCount(), 1)

        NotificationCenter.default.post(
            name: NSApplication.didResignActiveNotification,
            object: NSApplication.shared
        )
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        controller.togglePopup()

        XCTAssertEqual(Self.visiblePopupCount(), 1)
    }

    private static func visiblePopupCount() -> Int {
        NSApplication.shared.windows.filter { window in
            window is PopupWindow && window.isVisible
        }.count
    }
}
