import Foundation

struct Character : Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let dialogue: String
}