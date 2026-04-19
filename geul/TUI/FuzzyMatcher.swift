import Foundation

struct MatchedEntry: Equatable {
    let entry: FileEntry
    let score: Int
    let matchIndices: [Int]
}

enum FuzzyMatcher {
    static func filter(_ entries: [FileEntry], query: String) -> [MatchedEntry] {
        if query.isEmpty {
            return entries.map { MatchedEntry(entry: $0, score: 0, matchIndices: []) }
        }
        let matched = entries.compactMap { entry -> MatchedEntry? in
            guard let result = score(query: query, in: entry.relativePath) else { return nil }
            return MatchedEntry(entry: entry, score: result.score, matchIndices: result.indices)
        }
        return matched.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.entry.relativePath < rhs.entry.relativePath
        }
    }

    struct ScoreResult {
        let score: Int
        let indices: [Int]
    }

    static func score(query: String, in path: String) -> ScoreResult? {
        let queryChars = Array(query.lowercased())
        let pathChars = Array(path)
        let lowerPath = Array(path.lowercased())

        var queryIdx = 0
        var total = 0
        var indices: [Int] = []
        var lastMatchIdx: Int?

        for pathIdx in 0..<pathChars.count {
            guard queryIdx < queryChars.count else { break }
            if lowerPath[pathIdx] == queryChars[queryIdx] {
                total += 1
                if let last = lastMatchIdx, last == pathIdx - 1 {
                    total += 2 // 연속 매치 보너스
                }
                if isWordBoundary(pathChars, at: pathIdx) {
                    total += 3 // 단어 경계 보너스
                }
                indices.append(pathIdx)
                lastMatchIdx = pathIdx
                queryIdx += 1
            }
        }

        guard queryIdx == queryChars.count else { return nil }
        return ScoreResult(score: total, indices: indices)
    }

    private static func isWordBoundary(_ chars: [Character], at idx: Int) -> Bool {
        guard idx > 0 else { return true } // 맨 앞도 경계
        let prev = chars[idx - 1]
        if prev == "/" || prev == "_" || prev == "-" || prev == "." || prev == " " {
            return true
        }
        // camelCase 경계: 이전이 소문자, 현재가 대문자
        let cur = chars[idx]
        if prev.isLowercase && cur.isUppercase {
            return true
        }
        return false
    }
}
