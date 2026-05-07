import Foundation

enum FindAction: Equatable {
    case none
    case search(String)
    case next
    case previous
    case clear
}

struct FindRequest: Equatable {
    let id: Int
    let action: FindAction

    static let initial = FindRequest(id: 0, action: .none)
}

struct FindResult: Equatable {
    let query: String
    let currentIndex: Int
    let total: Int

    static let empty = FindResult(query: "", currentIndex: -1, total: 0)

    var hasMatches: Bool {
        total > 0
    }

    var displayText: String {
        if query.isEmpty {
            return ""
        }

        guard hasMatches else {
            return "No matches"
        }

        return "\(currentIndex + 1) of \(total)"
    }
}
