import SwiftUI

struct OnboardingView: View {
    var onDone: (_ launchAtLogin: Bool) -> Void
    var onSetShortcut: () -> Void

    @State private var launchAtLogin = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Welcome to geul")
                .font(.title)
            Text("geul이 메뉴바에 살고 있습니다. 세 가지 방법으로 열 수 있어요:")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Label("메뉴바 아이콘 클릭", systemImage: "menubar.arrow.up.rectangle")
                Label("Dock 아이콘 클릭", systemImage: "dock.rectangle")
                Label("전역 단축키 (설정하기 ▸)", systemImage: "keyboard")
            }

            Button("Set shortcut…") { onSetShortcut() }
                .buttonStyle(.link)

            Toggle("Launch at login", isOn: $launchAtLogin)

            HStack {
                Spacer()
                Button("Got it") { onDone(launchAtLogin) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
