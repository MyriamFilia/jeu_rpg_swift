import Foundation

class Player: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    var inventory: [String] //ou string id des items
    var currentRoomId: String
    var attackPower: Int
    var defense: Int
    var health: Int
    var score: Int

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

    //Implementation de la méthode hash(into:) pour le protocole Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    //Implementation de la méthode == pour le protocole Equatable
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }

    //Fonction pour ajouter un objet à l'inventaire
    func addItemToInventory(_ item: String) {
        inventory.append(item)
        //print("Tu as obtiens: \(item)")
    }


    func addScore(_ points: Int) {
        score += points
        //print("Ton score actuel est: \(score)")
    }

}