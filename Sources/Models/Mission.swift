struct Chapter: Codable {
    let id: String
    let title: String
    let description: String
    let roomId: String
    var isCompleted: Bool
}

struct Mission: Codable {
    let id: String
    let title: String
    let description: String
    var chapters: [Chapter]
    var isCompleted: Bool {
        chapters.allSatisfy { $0.isCompleted }
    }
}
