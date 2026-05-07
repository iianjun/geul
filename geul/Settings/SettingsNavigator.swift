import SwiftUI

@MainActor
final class SettingsNavigator: ObservableObject {
    static let shared = SettingsNavigator()
    @Published var requestedTab: SettingsView.Tab = .themes

    /// 다른 모듈(예: Onboarding)이 Settings를 열기 전에 호출해
    /// 원하는 탭을 지정할 수 있다. Settings 창이 이미 열려 있으면 즉시 전환된다.
    func request(_ tab: SettingsView.Tab) {
        requestedTab = tab
    }
}
