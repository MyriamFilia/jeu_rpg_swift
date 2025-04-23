import Foundation

struct Character : Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let dialogue: String?
    let availableTime: Int? // Période où le personnage est présent (0: matin, 1: midi, 2: soir, 3: nuit)
    let hints: [String: [String: String]]? // clé = type d’indice (puzzle, chapter, mission), valeur = [id: indice]
}

enum HintType: String, Codable {
    case puzzle
    case chapter
    case mission
}