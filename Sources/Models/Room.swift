import Foundation

struct Room: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let direction: [String : String]
    var items : [String]
    let puzzles: String?
    var monsters: [String]
    var characters: [String] = []
    var isLocked: Bool
}