import Foundation

class GameSession {
    let gameManager: GameManager
    let commandHandler: CommandHandler
    var activePlayerId: String?

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.commandHandler = CommandHandler(gameManager: gameManager) // Supprimé playerId
    }

    func start() {
        gameManager.loadGameData() // Charger les données JSON
        afficherMenuPrincipal()

        var choixValide = false
        while !choixValide {
            print("Entrez un numéro (1, 2 ou 3) : ", terminator: "")
            if let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                switch input {
                case "1":
                    if let playerId = gameManager.startNewGame() {
                        activePlayerId = playerId
                        commandHandler.setPlayerId(playerId) // Utiliser setPlayerId
                        boucleDeJeu()
                        choixValide = true
                    }
                case "2":
                    gameManager.resetGameState()
                    let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/save.json")
                    var gameSaves: [GameSave] = []
                    
                    if FileManager.default.fileExists(atPath: url.path) {
                        do {
                            let data = try Data(contentsOf: url)
                            if data.isEmpty {
                                print("Le fichier de sauvegarde est vide. Aucune sauvegarde trouvée.")
                            } else {
                                gameSaves = try JSONDecoder().decode([GameSave].self, from: data)
                            }
                        } catch {
                            print("Erreur lors du chargement des sauvegardes : \(error)")
                            print("Le fichier save.json peut être corrompu ou mal formé.")
                        }
                    } else {
                        print("Aucun fichier de sauvegarde trouvé à \(url.path).")
                    }

                    if gameSaves.isEmpty {
                        print("Aucune sauvegarde disponible. Veuillez commencer une nouvelle partie.")
                        continue
                    }

                    print("Joueurs disponibles :")
                    for (index, save) in gameSaves.enumerated() {
                        print("\(index + 1). \(save.playerName) (Position: \(save.playerPosition), Score: \(save.score))")
                    }
                    print("Entrez le numéro du joueur à charger : ", terminator: "")
                    
                    if let playerIndex = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), 
                       let index = Int(playerIndex), index > 0, index <= gameSaves.count {
                        let selectedPlayerId = gameSaves[index - 1].playerId
                        if let loadedPlayerId = gameManager.loadGameSaveData(playerId: selectedPlayerId) {
                            activePlayerId = loadedPlayerId
                            commandHandler.setPlayerId(loadedPlayerId) // Utiliser setPlayerId
                            boucleDeJeu()
                            choixValide = true
                        } else {
                            print("Erreur lors du chargement du joueur sélectionné.")
                        }
                    } else {
                        print("Choix invalide.")
                    }
                case "3":
                    quitterJeu()
                    choixValide = true
                default:
                    print("Choix invalide. Veuillez entrer 1, 2 ou 3.")
                }
            }
        }
    }

    private func afficherMenuPrincipal() {
        print("""
        ----------------------------------------------------
        BIENVENUE DANS LE DONJON D’ARGATH
        ----------------------------------------------------
        1. Commencer une nouvelle partie
        2. Charger une partie
        3. Quitter le jeu
        ----------------------------------------------------
        """)
    }

    private func boucleDeJeu() {
        while true {
            print("\nQue voulez-vous faire ?")
            if let userInput = readLine()?.lowercased() {
                if userInput == "menu"  {
                    if let playerId = activePlayerId {
                        gameManager.returnToMenu(playerId: playerId)
                        activePlayerId = nil // Réinitialiser l'ID du joueur actif
                        start() // Relancer le menu principal
                        break // Sortir de la boucle de jeu
                    } else {
                        print("Erreur : Aucun joueur actif.")
                    }
                } else {
                    commandHandler.handleCommand(userInput)
                    //afficherEtatJoueur()
                }
            }
        }
    }

    private func afficherEtatJoueur() {
        guard let playerId = activePlayerId, let player = gameManager.players[playerId] else {
            print("Erreur : Aucun joueur actif.")
            return
        }
        print("\n--- État actuel du joueur ---")
        print("Position : \(gameManager.rooms[player.currentRoomId]?.name ?? "Inconnue")")
        print("Score : \(player.score)")
        print("Inventaire : \(player.inventory.isEmpty ? "Vide" : player.inventory.joined(separator: ", "))")
        print("-----------------------------")
    }

    private func quitterJeu() {
        print("Voulez-vous sauvegarder votre progression avant de quitter ? (oui / non)")
        if let response = readLine()?.lowercased() {
            switch response {
            case "oui":
                if let playerId = activePlayerId {
                    gameManager.saveGame(playerId: playerId)
                    print("Partie sauvegardée. À bientôt !")
                } else {
                    print("Erreur : Aucun joueur actif pour sauvegarder.")
                }
            case "non":
                print("Merci d'avoir joué ! À bientôt.")
            default:
                print("Réponse invalide. Le jeu se termine sans sauvegarde.")
            }
        }
        exit(0)
    }
}