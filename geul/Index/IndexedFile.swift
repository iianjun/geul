import Foundation

struct IndexedFile: Equatable, Hashable {
    let url: URL
    let name: String
    let modifiedAt: Date
    let size: Int64
}
