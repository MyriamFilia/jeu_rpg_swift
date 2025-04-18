import Foundation

struct GameSave: Codable {
    var playerName: String
    var playerPosition: String
    var score: Int
    var inventory: [String]
    var solvedPuzzles: [String]
    //var storyProgress: String
    
}