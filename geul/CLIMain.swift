import Darwin
import Foundation

@main
enum CLIMain {
    static func main() {
        let args = CommandLine.arguments
        if args.count == 1 && isInteractiveTerminal() {
            exit(TUIController.runMain())
        }
        GeulApp.main()
    }

    private static func isInteractiveTerminal() -> Bool {
        guard isatty(STDIN_FILENO) != 0, isatty(STDOUT_FILENO) != 0 else { return false }
        let term = ProcessInfo.processInfo.environment["TERM"] ?? ""
        if term.isEmpty || term == "dumb" { return false }
        return true
    }
}
