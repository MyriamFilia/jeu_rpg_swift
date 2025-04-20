import Foundation

class CommandHandler {
    // MARK: - Propriétés
    var gameManager: GameManager
    var playerId: String?

    // MARK: - Initialisation
    init(gameManager: GameManager, playerId: String?) {
        self.gameManager = gameManager
        self.playerId = playerId
    }

    // MARK: - Méthodes principales de gestion de commandes
    func handleCommand(_ command: String) {
        let commandComponents = command.split(separator: " ")
        guard let action = commandComponents.first else { return }

        guard let playerId = playerId else {
            print("Erreur : Aucun joueur actif.")
            return
        }

        switch action {
        case "regarder":
            afficherSalleActuelle()

        case "aller":
            if commandComponents.count > 1 {
                let direction = commandComponents[1].lowercased()
                aller(direction)
            } else {
                print("Erreur : Direction manquante. Utilisez 'aller [direction]'.")
            }

        case "prendre":
            if commandComponents.count > 1 {
                let item = commandComponents[1].lowercased()
                gameManager.addItemToInventory(item, playerId: playerId)
            } else {
                print("Erreur : Objet manquant. Utilisez 'prendre [objet]'.")
            }

        case "utiliser":
            if commandComponents.count > 1 {
                let item = commandComponents[1].lowercased()
                gameManager.useItem(item, playerId: playerId)
            } else {
                print("Erreur : Objet manquant. Utilisez 'utiliser [objet]'.")
            }

        case "parler":
            if commandComponents.count > 2, commandComponents[1] == "à" {
                let characterName = commandComponents[2].lowercased()
                parlerA(characterName)
            } else {
                print("Erreur : Personnage manquant. Utilisez 'parler à [personnage]'.")
            }

        case "résoudre":
            let restOfCommand = commandComponents.dropFirst().joined(separator: " ")
            resoudreEnigme(restOfCommand)

        case "combattre":
            if commandComponents.count > 1 {
                let monsterId = commandComponents[1].lowercased()
                gameManager.fightMonster(monsterId: monsterId, playerId: playerId)
            } else {
                print("Erreur : Monstre manquant. Utilisez 'combattre [monstre]'.")
            }

        case "missions":
            gameManager.displayMissions()

        case "aide", "?":
            afficherAide()

        case "inventaire":
            afficherInventaire()

        case "sauvegarder":
            gameManager.saveGame(playerId: playerId)

        case "quitter":
            demanderSauvegarde()

        default:
            print("Commande invalide. Tapez 'aide' ou '?' pour voir la liste des commandes.")
        }
    }

    // MARK: - Commandes spécifiques
    func afficherSalleActuelle() {
        guard let playerId = playerId, let player = gameManager.players[playerId] else {
            print("Erreur : Aucun joueur actif.")
            return
        }
        gameManager.afficherSalleActuelle(for: player)
    }

    func aller(_ direction: String) {
        guard let playerId = playerId else {
            print("Erreur : Aucun joueur actif.")
            return
        }
        gameManager.move(playerId: playerId, to: direction)
    }

    func prendreItem(_ item: String) {
        print("Vous avez pris l'objet : \(item)")
    }

    func utiliserItem(_ item: String) {
        print("Vous utilisez l'objet : \(item)")
    }

    func parlerA(_ characterName: String) {
        print("Vous parlez à \(characterName).")
    }

    func resoudreEnigme(_ input: String) {
        guard let playerId = playerId, let player = gameManager.players[playerId] else {
            print("Erreur : Aucun joueur actif.")
            return
        }
        let components = input.split(separator: " ").map { String($0) }

        if components.isEmpty {
            guard let currentRoom = gameManager.rooms[player.currentRoomId],
                  let puzzleId = currentRoom.puzzles,
                  let puzzle = gameManager.puzzles[puzzleId], !puzzle.isSolved else {
                print("Il n'y a pas d'énigme à résoudre ici.")
                return
            }

            print("Voici l'énigme : \(puzzle.description)")
            print("Quelle est votre réponse ?")
            if let userAnswer = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                gameManager.resolvePuzzle(puzzleId: puzzleId, solution: userAnswer, playerId: playerId)
            } else {
                print("Aucune réponse donnée.")
            }
        }
    }

    func afficherInventaire() {
        guard let playerId = playerId, let player = gameManager.players[playerId] else {
            print("Erreur : Aucun joueur actif.")
            return
        }

        if player.inventory.isEmpty {
            print("Votre inventaire est vide.")
        } else {
            print("Inventaire :")
            for itemId in player.inventory {
                if let item = gameManager.items[itemId] {
                    print("- \(item.name): \(item.description)")
                } else {
                    print("- \(itemId) (inconnu)")
                }
            }
        }
    }

    // MARK: - Commande "aide"
    func afficherAide() {
        print("""
        Commandes disponibles :
        - regarder : Afficher la description de la salle actuelle.
        - aller [direction] : Se déplacer dans une direction (ex: aller nord).
        - prendre [objet] : Prendre un objet (ex: prendre clé).
        - utiliser [objet] : Utiliser un objet (ex: utiliser torche).
        - parler à [personnage] : Parler à un personnage (ex: parler à marchand).
        - résoudre : Résoudre une énigme dans la salle actuelle.
        - combattre [monstre] : Combattre un monstre (ex: combattre golem).
        - missions : Afficher les missions et leur progression.
        - inventaire : Afficher les objets dans votre inventaire.
        - sauvegarder : Sauvegarder votre progression.
        - quitter : Quitter le jeu.
        - aide / ? : Afficher cette aide.
        """)
    }

    // MARK: - Demander si l'utilisateur veut sauvegarder avant de quitter
    func demanderSauvegarde() {
        print("Voulez-vous sauvegarder avant de quitter ? (oui / non)")
        if let response = readLine()?.lowercased() {
            switch response {
            case "oui":
                if let playerId = playerId {
                    gameManager.saveGame(playerId: playerId)
                    print("Partie sauvegardée. Merci d'avoir joué ! À bientôt.")
                } else {
                    print("Erreur : Aucun joueur actif pour sauvegarder.")
                }
                exit(0)
            case "non":
                print("Merci d'avoir joué ! À bientôt.")
                exit(0)
            default:
                print("Réponse invalide. Le jeu se termine sans sauvegarde.")
                exit(0)
            }
        }
    }
}