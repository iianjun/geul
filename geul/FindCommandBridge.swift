import Combine

enum FindMenuCommand: Equatable {
    case none
    case showFindInterface
    case nextMatch
    case previousMatch
    case hideFindInterface
}

struct FindMenuRequest: Equatable {
    let id: Int
    let command: FindMenuCommand

    static let initial = FindMenuRequest(id: 0, command: .none)
}

final class FindCommandBridge: ObservableObject {
    @Published private(set) var request = FindMenuRequest.initial
    @Published private(set) var canFind = false
    @Published private(set) var isFindVisible = false
    @Published private(set) var hasQuery = false

    private var nextRequestID = 1

    func dispatch(_ command: FindMenuCommand) {
        request = FindMenuRequest(id: nextRequestID, command: command)
        nextRequestID += 1
    }

    func updateAvailability(
        canFind: Bool,
        isFindVisible: Bool,
        hasQuery: Bool
    ) {
        self.canFind = canFind
        self.isFindVisible = isFindVisible
        self.hasQuery = hasQuery
    }
}
