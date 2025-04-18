import Foundation

class CommandHandler {
    
    //Propriétés
    var gameManager: GameManager
    var player: Player?
    
    //Initialisation
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.player = gameManager.player
    }
    
    //Méthodes
    func handleCommand(_ command: String) {
        let commandComponents = command.split(separator: " ")
        guard let action = commandComponents.first else { return }
        
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
                    gameManager.addItemToInventory(item)
                } else {
                    print("Erreur : Objet manquant. Utilisez 'prendre [objet]'.")
                }
                
            case "utiliser":
                if commandComponents.count > 1 {
                    let item = commandComponents[1].lowercased()
                    gameManager.useItem(item)
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
                
            case "aide", "?":
                afficherAide()

            case "inventaire":
                afficherInventaire()

            case  "sauvegarder":
                gameManager.saveGame()

            case "quitter":
                print("Merci d'avoir joué ! À bientôt.")
                exit(0)
                
            default:
                print("Commande invalide. Tapez 'aide' ou '?' pour voir la liste des commandes.")
        }
    }
    
    // Commande "regarder"
    func afficherSalleActuelle() {
        gameManager.afficherSalleActuelle()
    }
    
    // Commande "aller"
    func aller(_ direction: String) {
        gameManager.move(to: direction)
    }
    
    // Commande "prendre"
    func prendreItem(_ item: String) {
        print("Vous avez pris l'objet : \(item)")
    }
    
    // Commande "utiliser"
    func utiliserItem(_ item: String) {
        print("Vous utilisez l'objet : \(item)")
    }
    
    // Commande "parler"
    func parlerA(_ characterName: String) {
        print("Vous parlez à \(characterName).")
    }
    
    // Commande "résoudre"
    func resoudreEnigme(_ input: String) {

        let components = input.split(separator: " ").map { String($0) }
        
        if components.count == 0 {
            guard let player = gameManager.player,
                let currentRoom = gameManager.rooms[player.currentRoomId],
                let puzzleId = currentRoom.puzzles,
                let puzzle = gameManager.puzzles[puzzleId], !puzzle.isSolved else {
                print("Il n'y a pas d'énigme à résoudre ici.")
                return
            }

            print("Voici l'énigme : \(puzzle.description)")
            print("Quelle est votre réponse ?")
            if let userAnswer = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                gameManager.resolvePuzzle(puzzleId: puzzleId, solution: userAnswer)
            } else {
                print("Aucune réponse donnée.")
            }
            return
        }
    }
    
    // Commande "inventaire"
    func afficherInventaire() {
      guard let player = gameManager.player else { return }

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

    
    // Commande "aide"
    func afficherAide() {
        print("""
        Commandes disponibles :
        - regarder : Afficher la description de la salle actuelle.
        - aller [direction] : Se déplacer dans une direction (ex: aller nord).
        - prendre [objet] : Prendre un objet (ex: prendre clé).
        - utiliser [objet] : Utiliser un objet (ex: utiliser torche).
        - parler à [personnage] : Parler à un personnage (ex: parler à marchand).
        - résoudre [énigme] : Résoudre une énigme.
        - aide / ? : Afficher cette aide.
        """)
    }

}