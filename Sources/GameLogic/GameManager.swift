import Foundation

class GameManager {
    // MARK: - Propriétés
    var rooms: [String: Room] = [:]
    var characters: [String: Character] = [:]
    var items: [String: Item] = [:]
    var puzzles: [String: Puzzle] = [:]
    var monsters: [String: Monster] = [:]
    var missions: [Mission] = []
    var players: [String: Player] = [:]

    // MARK: - Initialisation
    init() {}

    // MARK: - Intro
    func afficherIntro() {
        let introLines = [
            "",
            "La Légende raconte qu’au cœur des montagnes d’Iskarn,",
            "caché sous les ruines d’une cité oubliée,",
            "dort un artefact capable de manipuler le temps lui-même…",
            "",
            "On l’appelle l’Œil d’Argath.",
            "",
            "Aucun aventurier n’est jamais revenu de son sanctuaire.",
            "Jusqu’à aujourd’hui.",
            "",
            "----------------------------------------------------",
            "",
            "Une nuit noire. La pluie tombe en rafales.",
            "Tu avances à travers une forêt dense, chaque pas écrase des feuilles détrempées.",
            "Au loin, une lueur orangée filtre à travers les arbres morts.",
            "",
            "Tu dégages les ronces, et là, au milieu des ruines,",
            "tu vois une porte de pierre entrouverte, gravée de symboles oubliés.",
            "L’air qui s’en échappe est glacial.",
            "",
            "Tu allumes une torche.",
            "Le feu éclaire un couloir étroit, couvert de mousse et d’inscriptions anciennes.",
            "",
            "D’un pas décidé, tu franchis la porte...",
            "",
            "----------------------------------------------------",
            "",
            "Bienvenue dans le Donjon d’Argath.",
            "Ton but : trouver l’Œil d’Argath et ressortir vivant.",
            ""
        ]

        for line in introLines {
            print(line)
            Thread.sleep(forTimeInterval: 1.2)
        }
    }

    // MARK: - Chargement des données
    func loadGameData() {
        rooms = loadJSON("rooms.json")
        characters = loadJSON("characters.json")
        items = loadJSON("items.json")
        puzzles = loadJSON("puzzles.json")
        monsters = loadJSON("monsters.json")
        loadMissions()
    }

    func loadMissions() {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/missions.json")
        do {
            let data = try Data(contentsOf: url)
            missions = try JSONDecoder().decode([Mission].self, from: data)
        } catch {
            print("Erreur lors du chargement des missions : \(error)")
        }
    }

    private func loadJSON<T: Decodable>(_ fileName: String) -> [String: T] {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/\(fileName)")
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: T].self, from: data)
            return decoded
        } catch {
            print("Erreur lors du chargement de \(fileName) : \(error)")
            return [:]
        }
    }

    // Réinitialiser l'état du jeu
    func resetGameState() {
        loadGameData()
        players.removeAll()
    }

    // MARK: - Lancement du jeu
    func startNewGame() -> String? {
        resetGameState()
        afficherIntro()
        print("----------------------------------------------------")
        print("Quel est votre nom, aventurier ?")
        let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Inconnu"

        print("----------------------------------------------------")
        print("Bienvenue, \(name) !")
        print("Vous vous réveillez dans une pièce sombre, entouré de murs de pierre.")
        print("----------------------------------------------------")

        if let startingRoom = rooms["entree"] {
            let player = Player(name: name, startingRoomId: startingRoom.id)
            players[player.id] = player
            afficherSalleActuelle(for: player)
            saveGame(playerId: player.id)
            return player.id
        } else {
            print("Erreur : Aucune salle de départ trouvée.")
            return nil
        }
    }

    // MARK: - Déplacement et Affichage de salle
    func move(playerId: String, to direction: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Erreur : Impossible de trouver la salle actuelle.")
            return
        }

        guard let nextRoomId = currentRoom.direction[direction], let nextRoom = rooms[nextRoomId] else {
            print("Vous ne pouvez pas aller par là.")
            return
        }

        if nextRoom.isLocked {
            if nextRoomId == "verrouillee" && player.inventory.contains("cle") {
                rooms[nextRoomId]?.isLocked = false
                print("Vous utilisez la clé pour déverrouiller la salle.")
            } else if nextRoomId == "sortie" && player.inventory.contains("artefact") {
                rooms[nextRoomId]?.isLocked = false
                print("Vous utilisez l’artefact pour déverrouiller la sortie.")
            } else {
                print("Cette salle est verrouillée. Vous avez besoin d’un objet spécifique.")
                return
            }
        }

        player.currentRoomId = nextRoom.id
        print("Vous vous déplacez vers la salle : \(nextRoom.name)")
        afficherSalleActuelle(for: player)
        checkMissionProgression(roomId: nextRoom.id, playerId: playerId)
    }

    func afficherSalleActuelle(for player: Player) {
        guard let salle = rooms[player.currentRoomId] else {
            print("Impossible de trouver la salle actuelle.")
            return
        }

        print("\n=== \(salle.name.uppercased()) ===")
        print(salle.description)

        // Afficher un message narratif pour les chapitres actifs
        if let activeMissionIndex = getActiveMissionIndex() {
            let mission = missions[activeMissionIndex]
            for chapter in mission.chapters {
                if chapter.roomId == salle.id && !chapter.isCompleted {
                    print("📜 Mission : \(chapter.description)")
                    break
                }
            }
        }

        print("\n→ Sorties : \(salle.direction.keys.joined(separator: ", "))")

        let availableItems = salle.items.filter { !player.inventory.contains($0) }
        if !availableItems.isEmpty {
            print("→ Objets présents : \(availableItems.joined(separator: ", "))")
        }
        if !salle.characters.isEmpty {
            print("→ Personnages : \(salle.characters.joined(separator: ", "))")
        }
        if !salle.monsters.isEmpty {
            print("→ Dangers : \(salle.monsters.joined(separator: ", "))")
        }
        if let puzzleId = salle.puzzles, let puzzle = puzzles[puzzleId], !puzzle.isSolved {
            print("→ Une énigme semble bloquer le chemin ici : \(puzzle.description)")
        }
    }

    // MARK: - Énigmes
    func resolvePuzzle(puzzleId: String, solution: String, playerId: String) {
        guard let player = players[playerId], let puzzle = puzzles[puzzleId] else {
            print("Erreur : Énigme ou joueur non trouvé.")
            return
        }

        if puzzle.isSolved {
            print("Cette énigme a déjà été résolue.")
            return
        }

        if puzzle.solution.lowercased() == solution.lowercased() {
            puzzles[puzzleId]?.isSolved = true
            player.addItemToInventory(puzzle.reward)
            player.addScore(10)
            print("Félicitations ! Vous avez résolu l'énigme. Vous avez reçu : \(puzzle.reward) et 10 points. Score : \(player.score)")
            checkMissionProgression(roomId: puzzle.roomId, playerId: playerId)
        } else {
            print("Mauvaise réponse. Essayez encore.")
        }
    }

    // MARK: - Objets et Inventaire
    func addItemToInventory(_ itemId: String, playerId: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Objet introuvable dans cette pièce.")
            return
        }

        if currentRoom.items.contains(itemId) && !player.inventory.contains(itemId) {
            player.inventory.append(itemId)
            if let item = items[itemId] {
                print("Vous avez pris l’objet : \(item.name)")
            } else {
                print("Objet ajouté, mais non reconnu.")
            }
            checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
        } else {
            print("Objet introuvable ou déjà pris.")
        }
    }

    func useItem(_ itemId: String, playerId: String) {
        guard let player = players[playerId] else { return }

        if player.inventory.contains(itemId) {
            print("Vous utilisez l’objet : \(itemId)")
            if let index = player.inventory.firstIndex(of: itemId) {
                player.inventory.remove(at: index)
            }
            checkMissionProgression(roomId: player.currentRoomId, playerId: playerId)
        } else {
            print("Vous ne possédez pas cet objet.")
        }
    }

    // MARK: - Combattre les monstres
    func fightMonster(monsterId: String, playerId: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Erreur : Impossible de combattre ici.")
            return
        }

        if currentRoom.monsters.contains(monsterId) {
            if monsterId == "golem" {
                if player.inventory.contains("amulette") {
                    print("Vous brandissez l’amulette protectrice, et le golem s’effondre en poussière !")
                    rooms[currentRoom.id]?.monsters.removeAll { $0 == "golem" }
                    player.addScore(50)
                    print("Vous gagnez 50 points. Score total : \(player.score)")
                    checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
                } else {
                    print("Le golem est trop puissant ! Vous avez besoin d’une amulette protectrice.")
                }
            } else {
                print("Ce monstre n’est pas reconnu.")
            }
        } else {
            print("Aucun monstre à combattre ici.")
        }
    }

    // MARK: - Sauvegarde et Chargement
    func saveGame(playerId: String) {
        guard let player = players[playerId] else {
            print("Erreur : Aucun joueur trouvé pour sauvegarder.")
            return
        }

        let completedChapters = missions.flatMap { mission in
            mission.chapters.filter { $0.isCompleted }.map { $0.id }
        }

        let newSave = GameSave(
            playerId: player.id,
            playerName: player.name,
            playerPosition: player.currentRoomId,
            score: player.score,
            inventory: player.inventory,
            solvedPuzzles: puzzles.filter { $0.value.isSolved }.map { $0.key },
            completedChapters: completedChapters
        )

        var gameSaves: [GameSave] = []
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/save.json")
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                if data.isEmpty {
                    print("Le fichier save.json est vide. Initialisation avec une nouvelle liste.")
                } else {
                    do {
                        gameSaves = try JSONDecoder().decode([GameSave].self, from: data)
                    } catch {
                        print("Erreur lors du chargement des sauvegardes existantes : \(error)")
                        print("Le fichier save.json semble corrompu. Réinitialisation avec une nouvelle liste.")
                        gameSaves = []
                    }
                }
            } catch {
                print("Erreur lors de la lecture de save.json : \(error)")
                print("Création d'une nouvelle liste de sauvegardes.")
            }
        } else {
            print("Aucun fichier save.json trouvé. Création d'un nouveau fichier.")
        }

        if let index = gameSaves.firstIndex(where: { $0.playerId == playerId }) {
            gameSaves[index] = newSave
        } else {
            gameSaves.append(newSave)
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(gameSaves)
            try data.write(to: url)
            print("Jeu sauvegardé avec succès pour \(player.name).")
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }

    func loadGameSaveData(playerId: String? = nil) -> String? {
        resetGameState()

        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/save.json")

        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                if data.isEmpty {
                    print("Le fichier de sauvegarde est vide.")
                    return nil
                }
                let gameSaves = try JSONDecoder().decode([GameSave].self, from: data)
                
                if let targetPlayerId = playerId {
                    guard let gameSave = gameSaves.first(where: { $0.playerId == targetPlayerId }) else {
                        print("Erreur : Joueur avec l'ID \(targetPlayerId) non trouvé dans les sauvegardes.")
                        return nil
                    }

                    if let startingRoom = rooms[gameSave.playerPosition] {
                        let player = Player(name: gameSave.playerName, startingRoomId: startingRoom.id, id: gameSave.playerId)
                        player.inventory = gameSave.inventory
                        player.score = gameSave.score
                        for puzzleId in gameSave.solvedPuzzles {
                            puzzles[puzzleId]?.isSolved = true
                        }
                        if !gameSave.completedChapters.isEmpty {
                            for chapterId in gameSave.completedChapters {
                                for i in 0..<missions.count {
                                    for j in 0..<missions[i].chapters.count {
                                        if missions[i].chapters[j].id == chapterId {
                                            missions[i].chapters[j].isCompleted = true
                                        }
                                    }
                                }
                            }
                        }
                        players[player.id] = player
                        print("Heureux de te revoir, \(gameSave.playerName).")
                        afficherSalleActuelle(for: player)
                        return player.id
                    } else {
                        print("Erreur : La salle de départ pour \(gameSave.playerName) est introuvable.")
                        return nil
                    }
                } else {
                    var lastPlayerId: String?
                    for gameSave in gameSaves {
                        if let startingRoom = rooms[gameSave.playerPosition] {
                            let player = Player(name: gameSave.playerName, startingRoomId: startingRoom.id, id: gameSave.playerId)
                            player.inventory = gameSave.inventory
                            player.score = gameSave.score
                            for puzzleId in gameSave.solvedPuzzles {
                                puzzles[puzzleId]?.isSolved = true
                            }
                            if !gameSave.completedChapters.isEmpty {
                                for chapterId in gameSave.completedChapters {
                                    for i in 0..<missions.count {
                                        for j in 0..<missions[i].chapters.count {
                                            if missions[i].chapters[j].id == chapterId {
                                                missions[i].chapters[j].isCompleted = true
                                            }
                                        }
                                    }
                                }
                            }
                            players[player.id] = player
                            lastPlayerId = player.id
                        } else {
                            print("Erreur : La salle de départ pour \(gameSave.playerName) est introuvable.")
                        }
                    }

                    if let lastPlayerId = lastPlayerId {
                        return lastPlayerId
                    } else {
                        print("Aucune sauvegarde valide trouvée.")
                        return nil
                    }
                }
            } else {
                print("Aucun fichier de sauvegarde trouvé à \(url.path).")
                return nil
            }
        } catch {
            print("Erreur lors du chargement : \(error)")
            return nil
        }
    }

    // MARK: - Missions et progression
    func checkMissionProgression(roomId: String, playerId: String) {
        guard let player = players[playerId], let activeMissionIndex = getActiveMissionIndex() else {
            return
        }

        let mission = missions[activeMissionIndex]
        for (j, chapter) in mission.chapters.enumerated() {
            if chapter.roomId == roomId && !chapter.isCompleted {
                var canComplete = false
                switch chapter.id {
                case "chap1": // La Crypte Silencieuse (statues) : Résoudre puzzle1
                    canComplete = puzzles["puzzle1"]?.isSolved ?? false
                case "chap2": // Les Murmures de l’Est (echo) : Résoudre puzzle2
                    canComplete = puzzles["puzzle2"]?.isSolved ?? false
                case "chap3": // Le Puits Maudit (cavernes) : Résoudre puzzle5
                    canComplete = puzzles["puzzle5"]?.isSolved ?? false
                case "chap4": // Le Jardin du Néant (bibliotheque) : Résoudre puzzle3
                    canComplete = puzzles["puzzle3"]?.isSolved ?? false
                case "chap5": // Les Archives Perdues (sanctuaire) : Résoudre puzzle4
                    canComplete = puzzles["puzzle4"]?.isSolved ?? false
                case "chap6": // La Forge du Désespoir (sortie) : Posséder artefact
                    canComplete = player.inventory.contains("artefact")
                case "chap7": // La Chambre des Larmes (verrouillee) : Posséder cle
                    canComplete = player.inventory.contains("cle")
                case "chap8": // Le Sanctuaire d’Argath (sanctuaire) : Vaincre golem
                    canComplete = !(rooms["sanctuaire"]?.monsters.contains("golem") ?? true) && player.inventory.contains("artefact")
                default:
                    canComplete = false
                }

                if canComplete {
                    missions[activeMissionIndex].chapters[j].isCompleted = true
                    print("📜 Chapitre \(chapter.title) terminé !")
                    player.addScore(20)
                    print("Vous gagnez 20 points. Score total : \(player.score)")
                    if missions[activeMissionIndex].isCompleted {
                        print("🎉 Mission \(missions[activeMissionIndex].title) terminée !")
                        if activeMissionIndex < missions.count - 1 {
                            print("Nouvelle mission déverrouillée : \(missions[activeMissionIndex + 1].title)")
                        } else {
                            print("🏆 Félicitations ! Toutes les missions sont terminées !")
                        }
                    }
                    saveGame(playerId: playerId)
                }
                return
            }
        }
    }

    private func getActiveMissionIndex() -> Int? {
        for (index, mission) in missions.enumerated() {
            if !mission.isCompleted {
                let previousMissionsCompleted = index == 0 || missions[0..<index].allSatisfy { $0.isCompleted }
                if previousMissionsCompleted {
                    return index
                }
                return nil
            }
        }
        return nil
    }

    func displayMissions() {
        print("\n=== Progression des Missions ===")
        for (index, mission) in missions.enumerated() {
            let isActive = getActiveMissionIndex() == index
            let isCompleted = mission.isCompleted
            let status = isCompleted ? "✅ Complétée" : (isActive ? "📍 Active" : "🔒 Bloquée")
            print("\(status) \(mission.title) — \(mission.description)")
            for chapter in mission.chapters {
                let chapterStatus = chapter.isCompleted ? "✅" : "❌"
                print("   \(chapterStatus) \(chapter.title) — \(chapter.description)")
            }
        }
    }
}