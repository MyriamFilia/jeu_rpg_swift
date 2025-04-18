import Foundation

class GameSession {
    var gameManager: GameManager
    var commandHandler: CommandHandler

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.commandHandler = CommandHandler(gameManager: gameManager)
    }

    func start() {
        afficherMenuPrincipal()

        var choixValide = false
        while !choixValide {
            print("Entrez un numéro (1, 2 ou 3) : ", terminator: "")
            if let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                switch input {
                    case "1":
                        gameManager.startNewGame()
                        boucleDeJeu()
                        choixValide = true
                    case "2":
                        gameManager.loadGameSaveData()
                        boucleDeJeu()
                        choixValide = true
                    case "3":
                        print("À bientôt, aventurier !")
                        exit(0)
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
            }
        }
    }
}
