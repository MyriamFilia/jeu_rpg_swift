import Foundation

struct Player: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let inventory: [String] //ou string id des items
    let currentRoomId: String
    let attackPower: Int
    let defense: Int
    let health: Int
    let score: Int

    init(name: String, startingRoomId: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = "A brave adventurer"
        self.inventory = []
        self.currentRoomId = startingRoomId
        self.attackPower = 10
        self.defense = 5
        self.health = 100
        self.score = 0
    }

}