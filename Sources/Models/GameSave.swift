import Foundation

struct GameSave: Codable {
    let playerId: String
    let playerName: String
    let playerPosition: String
    let score: Int
    let inventory: [String]
    let solvedPuzzles: [String]
    let completedChapters: [String]
}