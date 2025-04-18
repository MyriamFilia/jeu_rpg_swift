import Foundation

class GameManager {
    //Propriétés
    var rooms: [String: Room] = [:]
    var characters: [String: Character] = [:]
    var items: [String: Item] = [:]
    var puzzles: [String: Puzzle] = [:]
    var monsters : [String: Monster] = [:]
    var player : Player?

    //Initialisation
    init() {
    }

    //Intro 
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

    //Chargement des données
    func loadJSONData<T: Decodable>(from fileName: String) -> [String: T]? {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/\(fileName)")
        do {
            let data = try Data(contentsOf: url)
            let decoded = JSONDecoder()
            let decodedData = try decoded.decode([String: T].self, from: data)
            return decodedData
        } catch {
            print("Erreur lors du chargement de \(fileName) : \(error)")
            return nil
        }
    }


    func loadGameData(){
        //Chargement des données
        if let loadedRooms: [String: Room] = loadJSONData(from: "rooms.json") {
            rooms = loadedRooms
        } else {
            print("Erreur lors du chargement des salles.")
        }
        if let loadedCharacters: [String: Character] = loadJSONData(from: "characters.json") {
            characters = loadedCharacters
        } else {
            print("Erreur lors du chargement des personnages.")
        }
        if let loadedItems: [String: Item] = loadJSONData(from: "items.json") {
            items = loadedItems
        } else {
            print("Erreur lors du chargement des objets.")
        }
        if let loadedPuzzles: [String: Puzzle] = loadJSONData(from: "puzzles.json") {
            puzzles = loadedPuzzles
        } else {
            print("Erreur lors du chargement des énigmes.")
        }
        if let loadedMonsters: [String: Monster] = loadJSONData(from: "monsters.json") {
            monsters = loadedMonsters
        } else {
            print("Erreur lors du chargement des monstres.")
        }
    }


    //Fonction pour se déplacer dans le jeu

    func move(to direction: String) {

        // Vérifier si le joueur est initialisé et s'il a une salle actuelle
        guard let player = player else {
            print("Erreur : Le joueur n'est pas initialisé.")
            return
        }
        
        // Vérifier si la salle actuelle du joueur existe
        guard let currentRoom = rooms[player.currentRoomId] else {
            print("La salle actuelle n'existe pas. Vous êtes perdu dans le néant.")
            return
        }
        
        // Vérifier si la direction est valide
        if let nextRoomId = currentRoom.direction[direction] {
            if let nextRoom = rooms[nextRoomId] {
                player.currentRoomId = nextRoom.id
                print("Vous vous déplacez vers la salle : \(nextRoom.name)")
                // Mettre à jour la salle actuelle du joueur
                afficherSalleActuelle()
            } else {
                print("Vous ne pouvez pas aller par là.")
            }
        } else {
            print("Direction invalide. Essayez une autre direction.")
        }
    }

    //Fonction pour afficher la salle actuellFiliae

    func afficherSalleActuelle() {
        // Vérifier si le joueur est initialisé et s'il a une salle actuelle
        guard let player = player else {
            print("Erreur : Le joueur n'est pas initialisé.")
            return
        }
        
        guard let salle = rooms[player.currentRoomId] else {
        print("Impossible de trouver la salle actuelle.")
        return
        }

        print("\n=== \(salle.name.uppercased()) ===")
        print(salle.description)
        
        print("\n→ Sorties : \(salle.direction.keys.joined(separator: ", "))")

        if !salle.items.isEmpty {
            print("→ Objets présents : \(salle.items.joined(separator: ", "))")
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


    //Fonction pour le début du jeu
    func startNewGame() {
        afficherIntro()
        print("----------------------------------------------------")
        print("Quel est votre nom, aventurier ?")
        let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Inconnu"

        print("----------------------------------------------------")
        print("Bienvenue, \(name) !")
        print("Vous vous réveillez dans une pièce sombre, entouré de murs de pierre.")
        print("----------------------------------------------------")
        // Créer le joueur
        if let startingRoom = rooms.values.first(where: { $0.id == "entree" }) {
            player = Player(name: name, startingRoomId: startingRoom.id)

            //Afficher directement la description de la salle d'entrée
            afficherSalleActuelle()
        } else {
            print("Erreur : Aucune salle de départ trouvée.")
        }
    }

    //Fonction pour résoudre une énigme
    func resolvePuzzle(puzzleId: String, solution: String) {
        guard let player = player else {
        print("Erreur : Aucun joueur trouvé.")
        return
        }
        if let puzzle = puzzles[puzzleId] {
            if puzzle.solution.lowercased() == solution.lowercased() {
                if !puzzle.isSolved {
                    // Marquer l'énigme comme résolue
                    puzzles[puzzleId]?.isSolved = true
                    
                    player.addItemToInventory(puzzle.reward)
                    
                    player.addScore(10)
                    
                    print("Félicitations ! Vous avez résolu l'énigme.")
                    print("Vous avez reçu : \(puzzle.reward) et 10 points. Votre score actuel est : \(player.score)")
                    
                } else {
                    // Si l'énigme est déjà résolue
                    print("Cette énigme a déjà été résolue.")
                }
            } else {
                // Si la solution est incorrecte
                print("Mauvaise réponse. Essayez encore.")

            }
        } else {
            // Si l'énigme n'existe pas
            print("Erreur : Énigme non trouvée.")
        }
    }


    //Fonction pour ajouter un objet à l'inventaire du joueur
    func addItemToInventory(_ itemId: String) {
        guard let player = player,
          let currentRoom = rooms[player.currentRoomId],
          let index = currentRoom.items.firstIndex(of: itemId) else {
        print("Objet introuvable dans cette pièce.")
        return
        }

        player.inventory.append(itemId)
        rooms[player.currentRoomId]?.items.remove(at: index)
        
        if let item = items[itemId] {
        print("Vous avez pris l’objet : \(item.name)")
        } else {
            print("Objet ajouté, mais non reconnu.")
        }
    }

    //Fonction pour utiliser un objet
    func useItem(_ itemId: String) {
        guard let player = player else { return }

        if player.inventory.contains(itemId) {
            // Tu peux ici définir des effets selon l’objet
            print("Vous utilisez l’objet : \(itemId)")

            // Exemple : un objet est consommé une fois utilisé
            if let index = player.inventory.firstIndex(of: itemId) {
                player.inventory.remove(at: index)
            }

            // Tu peux aussi déclencher des effets (ouvrir porte, etc.)
            // TODO: logique personnalisée selon les objets
        } else {
            print("Vous ne possédez pas cet objet.")
        }
    }


    //Fonction pour enrégistrer la partie

    func saveGame() {
        guard let player = player else {
            print("Erreur : Le joueur n'existe pas.")
            return
        }

        // Créer une sauvegarde avec les données du joueur
        let gameSave = GameSave(
            playerName: player.name,
            playerPosition: player.currentRoomId,
            score: player.score,
            inventory: player.inventory,
            solvedPuzzles: puzzles.filter { $0.value.isSolved }.map { $0.key }
        )
        
        // Convertir en JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(gameSave)
            
            // Enregistrer dans un fichier
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/save.json")
            try data.write(to: url)
            print("Jeu sauvegardé avec succès.")
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }

    func loadGameSaveData() {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/save.json")
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let gameSave = try decoder.decode(GameSave.self, from: data)
            
            // Restaurer les données dans le jeu
            if let startingRoom = rooms[gameSave.playerPosition] {
                // Créer le joueur avec les données de la sauvegarde
                player = Player(name: gameSave.playerName, startingRoomId: startingRoom.id)
                // Restaurer l'inventaire et le score
                player?.inventory = gameSave.inventory
                player?.score = gameSave.score
                // Marquer les énigmes résolues
                for puzzleId in gameSave.solvedPuzzles {
                    puzzles[puzzleId]?.isSolved = true
                }
                print("Jeu chargé avec succès.")
                afficherSalleActuelle() // Afficher la salle où le joueur était
            } else {
                print("Erreur : La salle de départ dans la sauvegarde est introuvable.")
            }
            
        } catch {
            print("Erreur lors du chargement : \(error)")
    }
}
}