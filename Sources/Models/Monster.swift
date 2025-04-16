import Foundation 

struct Monster : Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let attackPower: Int
    let defense: Int
    var health: Int
}