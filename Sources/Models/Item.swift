import Foundation

struct Item: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
}