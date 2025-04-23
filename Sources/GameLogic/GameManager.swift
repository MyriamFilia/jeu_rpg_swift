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
    var usedItems: [String: Set<String>] = [:]
    var gameTime: Int = 0 // Temps du jeu en tours

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
            "Ses trois fragments sont dispersés dans le donjon, protégés par des énigmes et un golem.",
            "Vous devez les réunir, reformer l’artefact, et choisir entre pouvoir et sacrifice.",
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
            "Chaque salle renferme un défi. Utilisez chaque objet pour révéler les secrets.",
            ""
        ]

        for line in introLines {
            print(line)
            Thread.sleep(forTimeInterval: 0.5)
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
        usedItems.removeAll()
        gameTime = 0
    }

    //
    func returnToMenu(playerId: String) {
        guard players[playerId] != nil else {
            print("Erreur : Joueur non trouvé.")
            return
        }
        print("Retour au menu principal...")
        resetGameState()
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
            usedItems[player.id] = []
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

        let isBackwardMove = player.visitedRooms.contains(nextRoomId)

        if let activeMissionIndex = getActiveMissionIndex(), !isBackwardMove {
            let mission = missions[activeMissionIndex]
            if let chapter = mission.chapters.first(where: { $0.roomId == currentRoom.id && !$0.isCompleted }) {
                let backwardDirections = ["sud": ["nord"], "nord": ["sud"], "est": ["ouest"], "ouest": ["est"], "bas": ["haut"], "haut": ["bas"]]
                let canMoveBack = backwardDirections[direction]?.contains { currentRoom.direction[$0] == nextRoomId } ?? false
                if !canMoveBack {
                    print("Vous devez compléter l’objectif de cette salle avant de continuer : \(chapter.title).")
                    return
                }
            }
        }

        if nextRoom.isLocked {
            if nextRoomId == "verrouillee" {
                print("Cette salle est verrouillée. Vous devez utiliser la clé pour la déverrouiller.")
                return
            } else if nextRoomId == "sortie" {
                print("La sortie est scellée. Vous devez utiliser l’Œil d’Argath pour l’ouvrir.")
                return
            } else {
                print("Cette salle est verrouillée. Vous avez besoin d’un objet spécifique.")
                return
            }
        }

        players[playerId]?.currentRoomId = nextRoom.id
        players[playerId]?.visitRoom(nextRoom.id)
        print("Vous vous déplacez vers la salle : \(nextRoom.name)")
        afficherSalleActuelle(for: player)
        checkMissionProgression(roomId: nextRoom.id, playerId: playerId)
        if nextRoom.id == "echo" && puzzles["puzzle2"]?.startTime == nil && puzzles["puzzle2"]?.isSolved == false {
            puzzles["puzzle2"]?.startTime = gameTime
            saveGame(playerId: playerId)
        }
    }

    func afficherSalleActuelle(for player: Player) {
        guard let salle = rooms[player.currentRoomId] else {
            print("Impossible de trouver la salle actuelle.")
            return
        }

        let timeOfDay = ["Matin", "Midi", "Soir", "Nuit"]
        let currentTime = timeOfDay[gameTime % 4]
        print("\n=== \(salle.name.uppercased()) === (Moment : \(currentTime))")
        print(salle.description)

        print("\n→ Sorties : \(salle.direction.keys.joined(separator: ", "))")
        
        let availableItems = salle.items.filter { !player.inventory.contains($0) }
        if !availableItems.isEmpty {
            print("→ Objets présents : \(availableItems.joined(separator: ", "))")
        }

        let presentCharacters = salle.characters.filter { characterId in
            guard let character = characters[characterId] else { return false }
            return character.availableTime == nil || character.availableTime == (gameTime % 4)
        }
        if !presentCharacters.isEmpty {
            print("→ Personnages : \(presentCharacters.joined(separator: ", "))")
        }

        if !salle.monsters.isEmpty {
            print("→ Dangers : \(salle.monsters.joined(separator: ", "))")
        }

        if let puzzleId = salle.puzzles, let puzzle = puzzles[puzzleId], !puzzle.isSolved {
            print("→ Une énigme semble bloquer le chemin ici : \(puzzle.description)")
            if let timeLimit = puzzle.timeLimit, let startTime = puzzle.startTime, gameTime > startTime + timeLimit {
                print("⚠️ Le temps pour résoudre cette énigme est écoulé ! Une pénalité peut s'appliquer.")
            }
        }

        if let activeMissionIndex = getActiveMissionIndex() {
            let mission = missions[activeMissionIndex]
            print("\n📜 Mission active : \(mission.title)")
            print("   Description : \(mission.description)")

            if let chapter = mission.chapters.first(where: { $0.roomId == salle.id && !$0.isCompleted }) {
                print("\n=== Objectif dans cette salle ===")
                print("Chapitre : \(chapter.title) (❌ Non complété)")
                print("Description : \(chapter.description)")
            } else {
                if salle.id == "statues" && mission.chapters.contains(where: { $0.id == "chap2" && !$0.isCompleted }) && rooms["verrouillee"]?.isLocked == true {
                    print("\n=== Objectif pour la progression ===")
                    print("Chapitre : La Porte Verrouillée (❌ Non complété)")
                    print("Description : Utiliser la clé pour ouvrir la porte au nord.")
                } else {
                    print("\nAucun objectif actif dans cette salle pour la mission actuelle.")
                }
            }
        } else {
            print("\n🏆 Toutes les missions sont terminées !")
            displayAchievements(playerId: player.id)
            print("\nTapez 'menu' pour revenir au menu principal.")
        }
    }

    // MARK: - Énigmes
    func resolvePuzzle(puzzleId: String, solution: String, playerId: String) {
        guard let player = players[playerId], let puzzle = puzzles[puzzleId], let currentRoom = rooms[player.currentRoomId] else {
            print("Erreur : Énigme, joueur, ou salle non trouvé.")
            return
        }

        if puzzle.isSolved {
            print("Cette énigme a déjà été résolue.")
            return
        }

        let requiredItems: [String: String] = [
            "puzzle4": "torche",
            "puzzle3": "livre"
        ]
        if let requiredItem = requiredItems[puzzleId] {
            if !player.inventory.contains(requiredItem) && puzzleId != "puzzle3" {
                print("Vous devez posséder \(requiredItem) pour résoudre cette énigme.")
                return
            }
            if !(usedItems[playerId]?.contains("\(requiredItem)_\(currentRoom.id)") ?? false) {
                print("Vous devez d’abord utiliser \(requiredItem) pour révéler l’énigme (tapez 'utiliser \(requiredItem)').")
                return
            }
        }

        var timePenaltyApplied = false
        if puzzleId == "puzzle2", let timeLimit = puzzle.timeLimit, let startTime = puzzle.startTime, gameTime > startTime + timeLimit {
            print("⚠️ Le temps pour résoudre cette énigme est écoulé. Pénalité de 5 points.")
            players[playerId]?.addScore(-5)
            timePenaltyApplied = true
        }

        if puzzle.solution.lowercased() == solution.lowercased() || (timePenaltyApplied && solution.lowercased() == "amulette") {
            puzzles[puzzleId]?.isSolved = true
            var receivedItems: [String] = []
            if let reward = puzzle.reward {
                players[playerId]?.addItemToInventory(reward)
                players[playerId]?.collectedItems.append(reward)
                if let itemData = items[reward] {
                    receivedItems.append(itemData.name)
                }
            }
            if !receivedItems.isEmpty {
                print("Vous avez reçu : \(receivedItems.joined(separator: ", "))")
            }
            players[playerId]?.addScore(10)
            print("Félicitations ! Vous avez résolu l'énigme. Score : \(player.score)")
            checkMissionProgression(roomId: puzzle.roomId, playerId: playerId)
            saveGame(playerId: playerId)
        } else {
            print("Mauvaise réponse. Essayez encore.")
            if timePenaltyApplied {
                print("Astuce : Avec le temps écoulé, vous pouvez utiliser l’amulette comme solution alternative.")
            }
        }
    }

    // MARK: - Objets et Inventaire
    func addItemToInventory(_ itemId: String, playerId: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Objet introuvable dans cette pièce.")
            return
        }

        if currentRoom.items.contains(itemId) && !player.inventory.contains(itemId) {
            players[playerId]?.addItemToInventory(itemId)
            if !player.collectedItems.contains(itemId) {
                players[playerId]?.collectedItems.append(itemId)
            }
            if let item = items[itemId] {
                print("Vous avez pris l’objet : \(item.name)")
            } else {
                print("Objet ajouté, mais non reconnu.")
            }
            checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
            saveGame(playerId: playerId)
        } else {
            if itemId == "amulette" && currentRoom.id == "echo" && puzzles["puzzle2"]?.isSolved == true && !player.inventory.contains("amulette") {
                players[playerId]?.addItemToInventory(itemId)
                if !player.collectedItems.contains(itemId) {
                    players[playerId]?.collectedItems.append(itemId)
                }
                print("Vous avez pris l’objet : Amulette")
                checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
                saveGame(playerId: playerId)
            } else {
                print("Objet introuvable ou déjà pris.")
            }
        }
    }

    func useItem(_ itemId: String, playerId: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Erreur : Joueur ou salle non trouvé.")
            return
        }

        if !player.inventory.contains(itemId) {
            print("Vous ne possédez pas cet objet.")
            return
        }

        switch itemId {
        case "cle":
            if currentRoom.direction.values.first(where: { $0 == "verrouillee" && rooms[$0]?.isLocked == true }) != nil {
                rooms["verrouillee"]?.isLocked = false
                if let index = player.inventory.firstIndex(of: "cle") {
                    players[playerId]?.inventory.remove(at: index)
                }
                players[playerId]?.visitRoom("verrouillee")
                print("Vous utilisez la clé pour déverrouiller la porte vers la salle verrouillée.")
                players[playerId]?.currentRoomId = "verrouillee"
                print("Vous entrez dans la salle verrouillée.")
                afficherSalleActuelle(for: player)
                checkMissionProgression(roomId: "verrouillee", playerId: playerId)
                saveGame(playerId: playerId)
            } else {
                print("La clé ne peut pas être utilisée ici. Essayez dans une salle avec une porte verrouillée à proximité.")
            }
        case "artefact":
            if currentRoom.id == "sanctuaire" && currentRoom.direction.values.contains("sortie") && rooms["sortie"]?.isLocked == true {
                rooms["sortie"]?.isLocked = false
                print("Vous utilisez l’Œil d’Argath pour déverrouiller la sortie.")
                players[playerId]?.currentRoomId = "sortie"
                print("Vous entrez dans la salle de la sortie.")
                afficherSalleActuelle(for: player)
                checkMissionProgression(roomId: "sortie", playerId: playerId)
                saveGame(playerId: playerId)
            } else if currentRoom.id == "sortie" {
                players[playerId]?.visitRoom("sortie")
                print("Vous placez l’Œil d’Argath dans la porte runique. Les runes s’illuminent, et la porte commence à s’ouvrir.")
                print("L’oracle apparaît et dit : 'Vous devez choisir : garder l’Œil pour son pouvoir, ou le détruire pour sceller la malédiction.'")
                print("Tapez 'choisir garder' ou 'choisir détruire' pour décider.")
                if let index = player.inventory.firstIndex(of: "artefact") {
                    players[playerId]?.inventory.remove(at: index)
                }
                checkMissionProgression(roomId: "sortie", playerId: playerId)
                saveGame(playerId: playerId)
            } else {
                print("L’Œil d’Argath ne peut pas être utilisé ici.")
            }
        case "torche":
            if currentRoom.id == "entree" && puzzles["puzzle4"]?.isSolved == false {
                print("Vous brandissez la torche, éclairant les symboles de l’énigme.")
                usedItems[playerId, default: []].insert("torche_entree")
                checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
                saveGame(playerId: playerId)
            } else {
                print("La torche ne peut pas être utilisée ici.")
            }
        case "fragment_carte":
            if currentRoom.id == "cavernes" {
                print("Vous examinez le fragment de carte, révélant un chemin caché vers une autre salle.")
                usedItems[playerId, default: []].insert("fragment_carte_cavernes")
                checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
                saveGame(playerId: playerId)
            } else {
                print("Le fragment de carte ne peut pas être utilisé ici.")
            }
        case "livre":
            if currentRoom.id == "bibliotheque" && puzzles["puzzle3"]?.isSolved == false {
                print("Vous ouvrez le livre, découvrant des indices pour l’énigme.")
                usedItems[playerId, default: []].insert("livre_bibliotheque")
                checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
                saveGame(playerId: playerId)
            } else {
                print("Le livre ne peut pas être utilisé ici.")
            }
        default:
            print("Cet objet ne peut pas être utilisé de cette manière.")
        }
    }

    func combineItems(_ itemIds: [String], playerId: String) {
        guard let player = players[playerId] else {
            print("Erreur : Joueur non trouvé.")
            return
        }

        let requiredItems = ["fragment_1", "fragment_2", "fragment_3", "connaissance"]
        if itemIds.sorted() == requiredItems.sorted() && itemIds.allSatisfy({ player.inventory.contains($0) }) {
            for item in requiredItems {
                if let index = player.inventory.firstIndex(of: item) {
                    players[playerId]?.inventory.remove(at: index)
                }
            }
            players[playerId]?.addItemToInventory("artefact")
            if !player.collectedItems.contains("artefact") {
                players[playerId]?.collectedItems.append("artefact")
            }
            print("Vous avez combiné les fragments et le savoir nécessaire pour reformer l’Œil d’Argath !")
            players[playerId]?.addScore(50)
            print("Vous gagnez 50 points. Score total : \(player.score)")
            checkMissionProgression(roomId: player.currentRoomId, playerId: playerId)
            saveGame(playerId: playerId)
        } else {
            print("Vous ne pouvez pas combiner ces objets ou il vous manque des objets nécessaires.")
        }
    }

    // MARK: - Combattre les monstres
    func fightMonster(_ monsterId: String, playerId: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Erreur : Joueur ou salle non trouvé.")
            return
        }

        if !currentRoom.monsters.contains(monsterId) {
            print("Aucun \(monsterId) à combattre ici.")
            return
        }

        if monsterId == "golem" && currentRoom.id == "sanctuaire" {
            if player.inventory.contains("amulette") {
                print("Vous utilisez l’amulette protectrice, et le golem s’effondre en poussière !")
                if let index = rooms["sanctuaire"]?.monsters.firstIndex(of: "golem") {
                    rooms["sanctuaire"]?.monsters.remove(at: index)
                }
                players[playerId]?.addItemToInventory("fragment_3")
                if !player.collectedItems.contains("fragment_3") {
                    players[playerId]?.collectedItems.append("fragment_3")
                }
                print("Vous avez trouvez le troisième fragment de l’Œil d’Argath sur les restes du golem.")
                players[playerId]?.addScore(50)
                print("Vous gagnez 50 points. Score total : \(player.score)")
                checkMissionProgression(roomId: currentRoom.id, playerId: playerId)
                saveGame(playerId: playerId)
            } else {
                print("Vous ne pouvez pas combattre le golem sans l’amulette protectrice !")
            }
        } else {
            print("Vous ne pouvez pas combattre ce monstre de cette manière.")
        }
    }

    // MARK: - Parler à un Personnage
    func talkToCharacter(characterId: String, playerId: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Erreur : Joueur ou salle non trouvé.")
            return
        }

        guard currentRoom.characters.contains(characterId), let character = characters[characterId] else {
            print("Ce personnage n’est pas ici.")
            return
        }

        if let availableTime = character.availableTime, availableTime != (gameTime % 4) {
            print("\(character.name) n’est pas disponible maintenant.")
            return
        }

        print("\(character.name) dit : \(character.dialogue ?? "Je n’ai rien à dire.")")
    }

    // MARK: - Choix final
    func chooseOutcome(_ choice: String, playerId: String) {
        guard let player = players[playerId], player.currentRoomId == "sortie" else {
            print("Vous ne pouvez pas faire ce choix ici.")
            return
        }

        if player.inventory.contains("artefact") {
            print("Vous devez d’abord utiliser l’Œil d’Argath pour ouvrir la porte (tapez 'utiliser artefact').")
            return
        }

        switch choice.lowercased() {
        case "garder":
            print("Vous choisissez de garder l’Œil d’Argath. Son pouvoir est immense, mais une ombre plane sur votre avenir...")
            players[playerId]?.addScore(100)
            print("Vous gagnez 100 points pour votre ambition. Score final : \(player.score)")
            print("🏆 Félicitations ! Vous avez quitté le donjon avec l’Œil d’Argath, mais à quel prix ?")
            checkMissionProgression(roomId: "sortie", playerId: playerId)
            saveGame(playerId: playerId)
            displayAchievements(playerId: playerId)
            print("\nTapez 'menu' pour revenir au menu principal.")
        case "détruire":
            print("Vous choisissez de détruire l’Œil d’Argath. La malédiction du donjon est scellée, et vous devenez un héros.")
            players[playerId]?.addScore(50)
            print("Vous gagnez 50 points pour votre sacrifice. Score final : \(player.score)")
            print("🏆 Félicitations ! Vous avez sauvé le monde en détruisant l’Œil d’Argath !")
            checkMissionProgression(roomId: "sortie", playerId: playerId)
            saveGame(playerId: playerId)
            displayAchievements(playerId: playerId)
            print("\nTapez 'menu' pour revenir au menu principal.")
        default:
            print("Choix invalide. Tapez 'choisir garder' ou 'choisir détruire'.")
        }
    }

    // MARK: - Attendre
    func wait(playerId: String) {
        guard let player = players[playerId] else {
            print("Erreur : Joueur non trouvé.")
            return
        }

        gameTime += 1
        print("Vous attendez un moment... Le temps avance. (Moment : \(["Matin", "Midi", "Soir", "Nuit"][gameTime % 4])")
        
       for (_, puzzle) in puzzles {
            if let timeLimit = puzzle.timeLimit, let startTime = puzzle.startTime, gameTime > startTime + timeLimit, !puzzle.isSolved {
                print("⚠️ Le temps pour résoudre l’énigme dans \(rooms[puzzle.roomId]?.name ?? "une salle") est écoulé.")
            }
        }

        afficherSalleActuelle(for: player)
        saveGame(playerId: playerId)
    }

    // MARK: - Afficher Carte
    func displayMap(playerId: String) {
        guard let player = players[playerId], let currentRoom = rooms[player.currentRoomId] else {
            print("Erreur : Joueur ou salle non trouvé.")
            return
        }

        print("\n========= CARTE DU DONJON ===========")
        let roomPositions: [String: (x: Int, y: Int)] = [
            "entree": (2, 4),       // Centre-bas
            "verrouillee": (3, 4),  // À droite (est) d'Entrée
            "cavernes": (3, 5),     // En bas (sud) de Verrouillée
            "echo": (4, 5),         // À droite (est) de Cavernes
            "statues": (4, 4),      // En haut (nord) d'Écho
            "bibliotheque": (4, 3), // En haut (nord) de Statues
            "sanctuaire": (4, 2),   // En haut (nord) de Bibliothèque
            "sortie": (4, 1)        // En haut (nord) de Sanctuaire
        ]

        // Abréviations des noms des salles pour les carrés
        let roomLabels: [String: String] = [
            "entree": "ENTR",
            "verrouillee": rooms["verrouillee"]?.isLocked == true ? "VERR🔒" : "VERR",
            "cavernes": "CAVE",
            "echo": "ECHO",
            "statues": "STAT",
            "bibliotheque": "BIBL",
            "sanctuaire": "SANC",
            "sortie": rooms["sortie"]?.isLocked == true ? "SORT🔒" : "SORT"
        ]

        // Dimensions de la grille
        let width = 7
        let height = 7
        var grid = [[String]](repeating: ["         "], count: height)
        for i in 0..<height {
            grid[i] = [String](repeating: "         ", count: width)
        }

        // Placer toutes les salles (visitées ou non)
        for (roomId, pos) in roomPositions {
            let label = roomLabels[roomId] ?? roomId
            let content: String
            if roomId == currentRoom.id {
                // Salle actuelle : ajouter la croix
                content = "\(label)❌"
            } else if player.visitedRooms.contains(roomId) {
                // Salle visitée : ajouter un carré vert
                content = "🟩 \(label)"
            } else {
                // Salle non visitée : ajouter un carré rouge
                content = "🟥 \(label)"
            }
            // Centrer le contenu dans une case de 10 caractères
            let paddedContent = content.padding(toLength: 6, withPad: " ", startingAt: 0)
            grid[pos.y][pos.x] = "+--------+\n| \(paddedContent) |\n+--------+"
        }

        // Ajouter les connexions avec des flèches directionnelles (seulement entre salles visitées)
        for (roomId, room) in rooms {
            if let pos = roomPositions[roomId], player.visitedRooms.contains(roomId) {
                for (dir, nextRoomId) in room.direction {
                    if let nextPos = roomPositions[nextRoomId], player.visitedRooms.contains(nextRoomId) {
                        switch dir {
                        case "nord":
                            if nextPos.y == pos.y - 2 {
                                grid[pos.y - 1][pos.x] = grid[pos.y - 1][pos.x] == "        " ? "  ↑  " : grid[pos.y - 1][pos.x]
                            }
                        case "sud":
                            if nextPos.y == pos.y + 2 {
                                grid[pos.y + 1][pos.x] = grid[pos.y + 1][pos.x] == "        " ? "  ↓  " : grid[pos.y + 1][pos.x]
                            }
                        case "est":
                            if nextPos.x == pos.x + 2 {
                                grid[pos.y][pos.x + 1] = grid[pos.y][pos.x + 1] == "        " ? "→    " : grid[pos.y][pos.x + 1]
                            }
                        case "ouest":
                            if nextPos.x == pos.x - 2 {
                                grid[pos.y][pos.x - 1] = grid[pos.y][pos.x - 1] == "        " ? "←    " : grid[pos.y][pos.x - 1]
                            }
                        default:
                            break
                        }
                    }
                }
            }
        }

        // Afficher la grille
        for y in 0..<height {
            var line1 = [String]()
            var line2 = [String]()
            var line3 = [String]()
            for x in 0..<width {
                if grid[y][x].contains("+--------+") {
                    let lines = grid[y][x].split(separator: "\n").map { String($0) }
                    line1.append(lines[0])
                    line2.append(lines[1])
                    line3.append(lines[2])
                } else {
                    line1.append(grid[y][x])
                    line2.append("       ")
                    line3.append("       ")
                }
            }
            print(line1.joined())
            print(line2.joined())
            print(line3.joined())
        }

        // Indiquer la salle actuelle
        print("\n📍 Vous êtes dans : \(currentRoom.name) (\(roomLabels[currentRoom.id] ?? currentRoom.id))")

        // Boussole pour clarifier les directions
        print("\n🧭 Boussole : Nord = ↑ (haut), Est = → (droite), Ouest = ← (gauche), Sud = ↓ (bas)")

        // Légende
        print("\nLégende :")
        print("|🟩| = Salle visitée, |❌| = Votre position, |🟥| = Non visitée, ↑↓←→ = Connexions (directions), 🔒 = Verrouillée")
        print("Salles :")
        for (roomId, pos) in roomPositions {
            let status = player.visitedRooms.contains(roomId) ? "Visitée" : "Non visitée"
            print("  - \(rooms[roomId]?.name ?? roomId) (\(roomLabels[roomId] ?? roomId), \(status))")
        }

        // Afficher l'objectif actif
        if let activeMissionIndex = getActiveMissionIndex() {
            let mission = missions[activeMissionIndex]
            if let chapter = mission.chapters.first(where: { !$0.isCompleted }) {
                print("\n🎯 Objectif actuel : \(chapter.title) (Salle : \(rooms[chapter.roomId]?.name ?? "Inconnue"))")
            }
        }
        print("============================")
    }

    
    // MARK: - Récapitulatif des Accomplissements
    func displayAchievements(playerId: String) {
        guard let player = players[playerId] else {
            print("Erreur : Joueur non trouvé.")
            return
        }

        print("\n=== RÉCAPITULATIF DE VOS ACCOMPLISSEMENTS ===")
        print("Aventurier : \(player.name)")
        print("Score final : \(player.score) points")

        print("\n🌍 Salles visitées (\(player.visitedRooms.count)/\(rooms.count)) :")
        if player.visitedRooms.isEmpty {
            print("   Aucune salle visitée.")
        } else {
            for roomId in player.visitedRooms.sorted() {
                if let room = rooms[roomId] {
                    print("   - \(room.name)")
                }
            }
        }

        let completedMissions = missions.filter { $0.chapters.allSatisfy { $0.isCompleted } }
        print("\n📜 Missions terminées (\(completedMissions.count)/\(missions.count)) :")
        if completedMissions.isEmpty {
            print("   Aucune mission terminée.")
        } else {
            for mission in completedMissions {
                print("   - \(mission.title) : \(mission.description)")
            }
        }

        let completedChapters = missions.flatMap { $0.chapters.filter { $0.isCompleted } }
        print("\n✅ Chapitres complétés (\(completedChapters.count)/\(missions.flatMap { $0.chapters }.count)) :")
        if completedChapters.isEmpty {
            print("   Aucun chapitre complété.")
        } else {
            for chapter in completedChapters {
                print("   - \(chapter.title) (Salle : \(rooms[chapter.roomId]?.name ?? "Inconnue"))")
            }
        }

        print("\n🎒 Objets collectés (\(player.collectedItems.count)) :")
        if player.collectedItems.isEmpty {
            print("   Aucun objet collecté.")
        } else {
            for itemId in player.collectedItems {
                if let item = items[itemId] {
                    print("   - \(item.name) : \(item.description)")
                } else {
                    print("   - \(itemId) (objet non reconnu)")
                }
            }
        }

        let solvedPuzzles = puzzles.filter { $0.value.isSolved }
        print("\n🧩 Énigmes résolues (\(solvedPuzzles.count)/\(puzzles.count)) :")
        if solvedPuzzles.isEmpty {
            print("   Aucune énigme résolue.")
        } else {
            for puzzle in solvedPuzzles.values {
                print("   - \(puzzle.description) (Solution : \(puzzle.solution))")
            }
        }

        let defeatedMonsters = monsters.filter { monster in
            !rooms.values.contains { $0.monsters.contains(monster.key) }
        }
        print("\n⚔️ Monstres vaincus (\(defeatedMonsters.count)/\(monsters.count)) :")
        if defeatedMonsters.isEmpty {
            print("   Aucun monstre vaincu.")
        } else {
            for monster in defeatedMonsters.values {
                print("   - \(monster.name) : \(monster.description)")
            }
        }

        print("\n💡 Indices reçus (\(player.receivedHints.count)) :")
        if player.receivedHints.isEmpty {
            print("   Aucun indice reçu.")
        } else {
            for hint in player.receivedHints {
                print("   - \(hint)")
            }
        }

        print("\nMerci d’avoir exploré le Donjon d’Argath !")
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

        let solvedPuzzles = puzzles.map { (id, puzzle) in
            Puzzle(
                id: puzzle.id,
                name: puzzle.name,
                description: puzzle.description,
                solution: puzzle.solution,
                isSolved: puzzle.isSolved,
                reward: puzzle.reward,
                roomId: puzzle.roomId,
                timeLimit: puzzle.timeLimit,
                startTime: puzzle.startTime
            )
        }


        let newSave = GameSave(
            playerId: player.id,
            playerName: player.name,
            playerPosition: player.currentRoomId,
            score: player.score,
            inventory: player.inventory,
            collectedItems: player.collectedItems,
            visitedRooms: Array(player.visitedRooms),
            receivedHints: player.receivedHints,
            solvedPuzzles: solvedPuzzles.map { $0.id },
            puzzleStates: solvedPuzzles,
            completedChapters: completedChapters,
            gameTime: gameTime
        )

        var gameSaves: [GameSave] = []
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/save.json")
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                if data.isEmpty {
                    //print("Le fichier save.json est vide. Initialisation avec une nouvelle liste.")
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
            //print("Jeu sauvegardé avec succès pour \(player.name).")
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
                        player.collectedItems = gameSave.collectedItems ?? []
                        player.visitedRooms = Set(gameSave.visitedRooms ?? [startingRoom.id])
                        player.receivedHints = gameSave.receivedHints ?? []
                        player.score = gameSave.score
                        for puzzle in gameSave.puzzleStates ?? [] {
                            puzzles[puzzle.id]?.isSolved = puzzle.isSolved
                            puzzles[puzzle.id]?.startTime = puzzle.startTime
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
                        usedItems[player.id] = []
                        if gameSave.inventory.contains("torche") && (gameSave.puzzleStates?.contains(where: { $0.id == "puzzle4" && $0.isSolved }) ?? false) {
                            usedItems[player.id]?.insert("torche_entree")
                        }
                        if gameSave.inventory.contains("fragment_carte") && gameSave.completedChapters.contains("chap3") {
                            usedItems[player.id]?.insert("fragment_carte_cavernes")
                        }
                        if gameSave.inventory.contains("livre") && (gameSave.puzzleStates?.contains(where: { $0.id == "puzzle3" && $0.isSolved }) ?? false) {
                            usedItems[player.id]?.insert("livre_bibliotheque")
                        }
                        gameTime = gameSave.gameTime ?? 0
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
                            player.collectedItems = gameSave.collectedItems ?? []
                            player.visitedRooms = Set(gameSave.visitedRooms ?? [startingRoom.id])
                            player.receivedHints = gameSave.receivedHints ?? []
                            player.score = gameSave.score
                            for puzzle in gameSave.puzzleStates ?? [] {
                                puzzles[puzzle.id]?.isSolved = puzzle.isSolved
                                puzzles[puzzle.id]?.startTime = puzzle.startTime
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
                            usedItems[player.id] = []
                            if gameSave.inventory.contains("torche") && (gameSave.puzzleStates?.contains(where: { $0.id == "puzzle4" && $0.isSolved }) ?? false) {
                                usedItems[player.id]?.insert("torche_entree")
                            }
                            if gameSave.inventory.contains("fragment_carte") && gameSave.completedChapters.contains("chap3") {
                                usedItems[player.id]?.insert("fragment_carte_cavernes")
                            }
                            if gameSave.inventory.contains("livre") && (gameSave.puzzleStates?.contains(where: { $0.id == "puzzle3" && $0.isSolved }) ?? false) {
                                usedItems[player.id]?.insert("livre_bibliotheque")
                            }
                            gameTime = gameSave.gameTime ?? 0
                            lastPlayerId = player.id
                        } else {
                            print("Erreur : La salle de départ pour \(gameSave.playerName) est introuvable.")
                        }
                    }

                    if let lastPlayerId = lastPlayerId {
                        print("Heureux de te revoir, \(players[lastPlayerId]!.name).")
                        afficherSalleActuelle(for: players[lastPlayerId]!)
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
            if !chapter.isCompleted {
                var canComplete = false
                switch chapter.id {
                case "chap1":
                    canComplete = player.inventory.contains("cle") && (puzzles["puzzle4"]?.isSolved ?? false)
                case "chap2":
                    canComplete = !rooms["verrouillee"]!.isLocked
                case "chap3":
                    canComplete = usedItems[playerId]?.contains("fragment_carte_cavernes") ?? false
                case "chap4":
                    canComplete = puzzles["puzzle1"]?.isSolved ?? false
                case "chap5":
                    canComplete = puzzles["puzzle2"]?.isSolved ?? false && player.inventory.contains("amulette")
                case "chap6":
                    canComplete = puzzles["puzzle3"]?.isSolved ?? false
                case "chap7":
                    canComplete = !(rooms["sanctuaire"]?.monsters.contains("golem") ?? true)
                case "chap8":
                    canComplete = player.inventory.contains("artefact")
                case "chap9":
                    canComplete = player.currentRoomId == "sortie" && !player.inventory.contains("artefact")
                default:
                    canComplete = false
                }

                if canComplete {
                    missions[activeMissionIndex].chapters[j].isCompleted = true
                    print("📜 Chapitre \(chapter.title) terminé !")
                    players[playerId]?.addScore(20)
                    print("Vous gagnez 20 points. Score total : \(player.score)")
                    if missions[activeMissionIndex].isCompleted {
                        print("🎉 Mission \(missions[activeMissionIndex].title) terminée !")
                        if activeMissionIndex < missions.count - 1 {
                            print("Nouvelle mission déverrouillée : \(missions[activeMissionIndex + 1].title)")
                        }
                    }
                    saveGame(playerId: playerId)
                }
            }
        }
    }

    func getActiveMissionIndex() -> Int? {
        for (index, mission) in missions.enumerated() {
            let isPreviousMissionCompleted = index == 0 || missions[index - 1].chapters.allSatisfy { $0.isCompleted }
            if !mission.isCompleted && isPreviousMissionCompleted {
                return index
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