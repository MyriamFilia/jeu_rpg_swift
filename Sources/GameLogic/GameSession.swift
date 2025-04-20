import Foundation

class GameSession {
    var gameManager: GameManager
    var commandHandler: CommandHandler
    var activePlayerId: String?

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.commandHandler = CommandHandler(gameManager: gameManager, playerId: nil)
    }

    func start() {
        afficherMenuPrincipal()

        var choixValide = false
        while !choixValide {
            print("Entrez un numéro (1, 2 ou 3) : ", terminator: "")
            if let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                switch input {
                case "1":
                    if let playerId = gameManager.startNewGame() {
                        activePlayerId = playerId
                        commandHandler.playerId = playerId
                    }
                    boucleDeJeu()
                    choixValide = true
                case "2":
                    // Réinitialiser l'état pour lister les sauvegardes proprement
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
                        continue // Revenir au menu principal
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
                            commandHandler.playerId = activePlayerId
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
                commandHandler.handleCommand(userInput)
                afficherEtatJoueur()
            }
        }
    }

    private func afficherEtatJoueur() {
        guard let playerId = activePlayerId, let player = gameManager.players[playerId] else {
            print("Erreur : Aucun joueur actif.")
            return
        }
        //print("\n--- État actuel du joueur ---")
        //print("Position : \(gameManager.rooms[player.currentRoomId]?.name ?? "Inconnue")")
        //print("Score : \(player.score)")
        //print("Inventaire : \(player.inventory)")
        //print("-----------------------------")
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