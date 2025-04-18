import Foundation

struct Puzzle: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let solution: String
    var isSolved: Bool
    let reward: String
    let roomId: String
}