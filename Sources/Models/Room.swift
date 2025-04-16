import Foundation

struct Room: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let direction: [String : String]
    let items : [String]
    let puzzles: [String]
    let monsters: [String]
}