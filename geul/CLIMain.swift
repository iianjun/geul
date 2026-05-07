import Darwin
import Foundation

enum CLIRoute: Equatable {
    case tui(URL)
    case app
}

@main
enum CLIMain {
    static func main() {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        switch route(
            arguments: CommandLine.arguments,
            isInteractiveTerminal: isInteractiveTerminal(),
            currentDirectory: currentDirectory
        ) {
        case .tui(let root):
            exit(TUIController.runMain(root: root))
        case .app:
            GeulApp.main()
        }
    }

    static func route(arguments: [String],
                      isInteractiveTerminal: Bool,
                      currentDirectory: URL) -> CLIRoute {
        guard isInteractiveTerminal else { return .app }
        if arguments.count == 1 {
            return .tui(currentDirectory.standardizedFileURL)
        }
        guard arguments.count == 2 else { return .app }

        let url = fileURL(for: arguments[1], currentDirectory: currentDirectory)
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return .app
        }
        return .tui(url)
    }

    private static func fileURL(for path: String, currentDirectory: URL) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path).standardizedFileURL
        }
        return currentDirectory.appendingPathComponent(path).standardizedFileURL
    }

    private static func isInteractiveTerminal() -> Bool {
        guard isatty(STDIN_FILENO) != 0, isatty(STDOUT_FILENO) != 0 else { return false }
        let term = ProcessInfo.processInfo.environment["TERM"] ?? ""
        if term.isEmpty || term == "dumb" { return false }
        return true
    }
}
