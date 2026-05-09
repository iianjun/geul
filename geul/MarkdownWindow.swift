import AppKit
import WebKit

final class MarkdownWindow: NSWindow {
    let findCommandBridge: FindCommandBridge
    private weak var markdownWebView: WKWebView?
    private var currentPageZoom: CGFloat = 1

    private enum PageZoom {
        static let step: CGFloat = 0.1
        static let minimum: CGFloat = 0.5
        static let maximum: CGFloat = 3
    }

    init(
        findCommandBridge: FindCommandBridge,
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        self.findCommandBridge = findCommandBridge
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
    }

    @objc override func performTextFinderAction(_ sender: Any?) {
        guard let action = textFinderAction(from: sender) else { return }
        dispatch(action)
    }

    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(performTextFinderAction(_:)),
           let action = NSTextFinder.Action(rawValue: item.tag) {
            return validate(action)
        }

        return super.validateUserInterfaceItem(item)
    }

    func validateFindCommand(tag: Int) -> Bool {
        guard let action = NSTextFinder.Action(rawValue: tag) else { return false }
        return validate(action)
    }

    func attachMarkdownWebView(_ webView: WKWebView) {
        markdownWebView = webView
        webView.pageZoom = currentPageZoom
    }

    func zoomIn() {
        setPageZoom(currentPageZoom + PageZoom.step)
    }

    func zoomOut() {
        setPageZoom(currentPageZoom - PageZoom.step)
    }

    private func dispatch(_ action: NSTextFinder.Action) {
        guard let command = findMenuCommand(for: action) else { return }
        findCommandBridge.dispatch(command)
    }

    private func setPageZoom(_ pageZoom: CGFloat) {
        currentPageZoom = min(max(pageZoom, PageZoom.minimum), PageZoom.maximum)
        markdownWebView?.pageZoom = currentPageZoom
    }

    private func validate(_ action: NSTextFinder.Action) -> Bool {
        switch action {
        case .showFindInterface:
            return findCommandBridge.canFind
        case .nextMatch, .previousMatch:
            return findCommandBridge.canFind && findCommandBridge.hasQuery
        case .hideFindInterface:
            return findCommandBridge.isFindVisible
        default:
            return false
        }
    }

    private func textFinderAction(from sender: Any?) -> NSTextFinder.Action? {
        if let menuItem = sender as? NSMenuItem {
            return NSTextFinder.Action(rawValue: menuItem.tag)
        }

        if let control = sender as? NSControl {
            return NSTextFinder.Action(rawValue: control.tag)
        }

        return nil
    }

    private func findMenuCommand(for action: NSTextFinder.Action) -> FindMenuCommand? {
        switch action {
        case .showFindInterface:
            return .showFindInterface
        case .nextMatch:
            return .nextMatch
        case .previousMatch:
            return .previousMatch
        case .hideFindInterface:
            return .hideFindInterface
        default:
            return nil
        }
    }
}
