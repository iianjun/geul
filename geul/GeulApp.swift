import SwiftUI

@main
struct GeulApp: App {
    private let fileURL: URL?

    init() {
        if CommandLine.arguments.count > 1 {
            let path = CommandLine.arguments[1]
            self.fileURL = URL(fileURLWithPath: path).standardized
        } else {
            self.fileURL = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(fileURL: fileURL)
        }
        .defaultSize(width: 900, height: 700)
    }
}
