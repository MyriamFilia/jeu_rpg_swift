import Foundation

class CommandHandler {
    let gameManager: GameManager
    var playerId: String?

    init(gameManager: GameManager) {
        self.gameManager = gameManager
    }

    func setPlayerId(_ id: String) {
        self.playerId = id
    }

    func handleCommand(_ command: String) {
        let components = command.lowercased().split(separator: " ").map { String($0) }
        guard !components.isEmpty else {
            print("Veuillez entrer une commande valide.")
            return
        }

        let action = components[0]
        let arguments = components.dropFirst().joined(separator: " ")

        guard let playerId = playerId else {
            print("Erreur : Aucun joueur actif.")
            return
        }

        switch action {
        case "regarder":
            if let player = gameManager.players[playerId] {
                gameManager.afficherSalleActuelle(for: player)
            }
        case "aller":
            if !arguments.isEmpty {
                gameManager.move(playerId: playerId, to: arguments)
            } else {
                print("Veuillez préciser une direction (ex. : aller nord).")
            }
        case "prendre":
            if !arguments.isEmpty {
                gameManager.addItemToInventory(arguments, playerId: playerId)
            } else {
                print("Veuillez préciser un objet à prendre (ex. : prendre torche).")
            }
        case "utiliser":
            if !arguments.isEmpty {
                gameManager.useItem(arguments, playerId: playerId)
            } else {
                print("Veuillez préciser un objet à utiliser (ex. : utiliser clé).")
            }
        case "combiner":
            if !arguments.isEmpty {
                let items = arguments.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                gameManager.combineItems(items, playerId: playerId)
            } else {
                print("Veuillez préciser les objets à combiner (ex. : combiner fragment_1,fragment_2,fragment_3,connaissance).")
            }
        case "resoudre":
            resoudreEnigme(playerId: playerId)
        case "combattre":
            if !arguments.isEmpty {
                gameManager.fightMonster(arguments, playerId: playerId)
            } else {
                print("Veuillez préciser un monstre à combattre (ex. : combattre golem).")
            }
        case "parler":
            if !arguments.isEmpty {
                parlerA(arguments, playerId: playerId)
            } else {
                print("Veuillez préciser à qui parler (ex. : parler bibliothecaire).")
            }
        case "choisir":
            if !arguments.isEmpty {
                gameManager.chooseOutcome(arguments, playerId: playerId)
            } else {
                print("Veuillez préciser un choix (ex. : choisir garder ou choisir détruire).")
            }
        case "inventaire":
            afficherInventaire()
        case "missions":
            gameManager.displayMissions()
        case "attendre":
            gameManager.wait(playerId: playerId)
        case "afficher":
            if arguments == "carte" {
                gameManager.displayMap(playerId: playerId)
            } else {
                print("Commande inconnue. Essayez 'afficher carte'.")
            }
        case "sauvegarder":
            gameManager.saveGame(playerId: playerId)
        case "quitter":
            demanderSauvegarde()
        case "menu":
            print("Retour au menu principal...")
        case "aide", "?":
            afficherAide()
        default:
            print("Commande non reconnue. Essayez : aide ou ?")
        }
    }

    func parlerA(_ characterName: String, playerId: String) {
        guard let player = gameManager.players[playerId],
              let currentRoom = gameManager.rooms[player.currentRoomId] else {
            print("Erreur : Aucun joueur ou salle active.")
            return
        }

        if !currentRoom.characters.contains(characterName) {
            print("Il n’y a pas de \(characterName) dans cette salle.")
            return
        }

        guard let character = gameManager.characters[characterName] else {
            print("Personnage non reconnu.")
            return
        }

        if let availableTime = character.availableTime, availableTime != (gameManager.gameTime % 4) {
            print("\(character.name) n’est pas disponible maintenant.")
            return
        }

        print("\(character.name) dit : \(character.dialogue ?? "Je n’ai rien à dire.")")

        let hasPuzzle = currentRoom.puzzles != nil &&
            gameManager.puzzles[currentRoom.puzzles!] != nil &&
            !gameManager.puzzles[currentRoom.puzzles!]!.isSolved &&
            character.hints?["puzzle"]?[currentRoom.puzzles!] != nil
        let hasChapter = gameManager.getActiveMissionIndex() != nil &&
            gameManager.missions[gameManager.getActiveMissionIndex()!].chapters
                .first(where: { $0.roomId == currentRoom.id && !$0.isCompleted }) != nil &&
            character.hints?["chapter"]?[
                gameManager.missions[gameManager.getActiveMissionIndex()!]
                    .chapters.first(where: { $0.roomId == currentRoom.id && !$0.isCompleted })!.id
            ] != nil
        let hasMission = gameManager.getActiveMissionIndex() != nil &&
            character.hints?["mission"]?[
                gameManager.missions[gameManager.getActiveMissionIndex()!].id
            ] != nil

        var options: [(String, String)] = []
        if hasPuzzle { options.append(("1", "Indice pour l’énigme")) }
        if hasChapter { options.append(("2", "Indice pour le chapitre")) }
        if hasMission { options.append(("3", "Indice pour la mission")) }

        if options.isEmpty {
            print("Ce personnage n’a aucun indice à offrir pour le moment.")
            return
        }

        print("Que veux-tu savoir ?")
        for (number, description) in options {
            print("(\(number)) \(description)")
        }
        print("Entre le numéro de ton choix (ou tapez autre chose pour annuler) : ", terminator: "")

        if let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
            switch choice {
            case "1" where hasPuzzle:
                if let puzzleId = currentRoom.puzzles,
                   let hint = character.hints?["puzzle"]?[puzzleId] {
                    print("Indice pour l’énigme : \(hint)")
                    gameManager.players[playerId]?.receiveHint(hint)
                    gameManager.saveGame(playerId: playerId)
                } else {
                    print("Erreur : Indice pour l’énigme non disponible.")
                }
            case "2" where hasChapter:
                if let missionIndex = gameManager.getActiveMissionIndex(),
                   let chapter = gameManager.missions[missionIndex].chapters
                       .first(where: { $0.roomId == currentRoom.id && !$0.isCompleted }),
                   let hint = character.hints?["chapter"]?[chapter.id] {
                    print("Indice pour le chapitre : \(hint)")
                    gameManager.players[playerId]?.receiveHint(hint)
                    gameManager.saveGame(playerId: playerId)
                } else {
                    print("Erreur : Indice pour le chapitre non disponible.")
                }
            case "3" where hasMission:
                if let missionIndex = gameManager.getActiveMissionIndex(),
                   let hint = character.hints?["mission"]?[gameManager.missions[missionIndex].id] {
                    print("Indice pour la mission : \(hint)")
                    gameManager.players[playerId]?.receiveHint(hint)
                    gameManager.saveGame(playerId: playerId)
                } else {
                    print("Erreur : Indice pour la mission non disponible.")
                }
            default:
                print("Choix annulé ou invalide. Parlez à nouveau au personnage si nécessaire.")
            }
        } else {
            print("Aucune réponse donnée.")
        }
    }

    func resoudreEnigme(playerId: String) {
        guard let player = gameManager.players[playerId],
              let currentRoom = gameManager.rooms[player.currentRoomId],
              let puzzleId = currentRoom.puzzles,
              let puzzle = gameManager.puzzles[puzzleId], !puzzle.isSolved else {
            print("Il n’y a pas d’énigme à résoudre ici ou elle est déjà résolue.")
            return
        }

        print("Voici l’énigme : \(puzzle.description)")
        print("Quelle est votre réponse ?")
        if let userAnswer = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
            gameManager.resolvePuzzle(puzzleId: puzzleId, solution: userAnswer, playerId: playerId)
        } else {
            print("Aucune réponse donnée.")
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

    func afficherAide() {
        print("""
        Commandes disponibles :
        - regarder : Afficher la description de la salle actuelle.
        - aller [direction] : Se déplacer dans une direction (ex. : aller nord).
        - prendre [objet] : Prendre un objet (ex. : prendre torche).
        - utiliser [objet] : Utiliser un objet (ex. : utiliser clé).
        - combiner [objets] : Combiner des objets (ex. : combiner fragment_1,fragment_2,fragment_3,connaissance).
        - résoudre : Résoudre une énigme dans la salle actuelle.
        - combattre [monstre] : Combattre un monstre (ex. : combattre golem).
        - parler [personnage] : Parler à un personnage (ex. : parler bibliothecaire).
        - choisir [option] : Faire un choix final (ex. : choisir garder ou choisir détruire).
        - inventaire : Afficher les objets dans votre inventaire.
        - missions : Afficher la progression des missions.
        - attendre : Faire avancer le temps d’un tour.
        - afficher carte : Afficher la carte du donjon.
        - sauvegarder : Sauvegarder la partie.
        - quitter : Quitter le jeu (avec option de sauvegarde).
        - aide : Afficher cette aide.
        """)
    }

    func demanderSauvegarde() {
        guard let playerId = playerId else {
            print("Erreur : Aucun joueur actif.")
            return
        }
        print("Voulez-vous sauvegarder avant de retourner au menu principal ? (oui/non)")
        if let response = readLine()?.lowercased(), response == "oui" {
            gameManager.saveGame(playerId: playerId)
            print("Jeu sauvegardé. Retour au menu principal...")
        } else {
            print("Retour au menu principal...")
        }
    }
}