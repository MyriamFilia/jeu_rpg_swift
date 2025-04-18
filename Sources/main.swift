import Foundation

// Création de l'instance du GameManager et chargement des données
let game = GameManager()
game.loadGameData()

// Lancer la session de jeu
GameSession(gameManager: game).start()
