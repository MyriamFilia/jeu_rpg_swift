import Foundation

class Player: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    var inventory: [String]
    var collectedItems: [String]
    var currentRoomId: String
    var score: Int
    var visitedRooms: Set<String>
    var receivedHints: [String]

    init(name: String, startingRoomId: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = "Brave Aventurier"
        self.inventory = []
        self.collectedItems = []
        self.currentRoomId = startingRoomId
        self.score = 0
        self.visitedRooms = [startingRoomId]
        self.receivedHints = []
    }

    init(name: String, startingRoomId: String, id: String) {
        self.id = id
        self.name = name
        self.description = "Brave Aventurier"
        self.inventory = []
        self.collectedItems = []
        self.currentRoomId = startingRoomId
        self.score = 0
        self.visitedRooms = [startingRoomId]
        self.receivedHints = []
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }

    func addItemToInventory(_ item: String) {
        if !inventory.contains(item) {
            inventory.append(item)
        }
        if !collectedItems.contains(item) {
            collectedItems.append(item)
        }
    }

    func addScore(_ points: Int) {
        score += points
    }

    func visitRoom(_ roomId: String) {
        visitedRooms.insert(roomId)
    }

    func receiveHint(_ hint: String) {
        if !receivedHints.contains(hint) {
            receivedHints.append(hint)
        }
    }
}