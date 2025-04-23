import Foundation

struct GameSave: Codable {
        let playerId: String
        let playerName: String
        let playerPosition: String
        let score: Int
        let inventory: [String]
        let collectedItems: [String]?
        let visitedRooms: [String]?
        let receivedHints: [String]?
        let solvedPuzzles: [String]
        let puzzleStates: [Puzzle]?
        let completedChapters: [String]
        let gameTime: Int?
    }