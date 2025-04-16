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

    //Fonction pour afficher le menu principal
    func afficherMenuPrincipal() {
        print("----------------------------------------------------")
        print("1. Commencer une nouvelle partie")
        print("2. Charger une partie")
        print("3. Quitter le jeu")
        print("----------------------------------------------------")
    }

    //Fonction pour gerer le menu
    func choixMenu(){
        
    }


    //Les methodes

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


    //Fonction pour le début du jeu
    func startGame() {
        afficherIntro()
        print("----------------------------------------------------")
        print("Quel est votre nom, aventurier ?")
        let name = readLine() ?? "Inconnu"
        print("----------------------------------------------------")
        print("Bienvenue, \(name) !")
        print("Vous vous réveillez dans une pièce sombre, entouré de murs de pierre.")
        print("----------------------------------------------------")
        // Créer le joueur
        if let startingRoom = rooms["entree"] {
            player = Player(name: name, startingRoomId: startingRoom.id)
            print("Vous êtes dans la salle : \(startingRoom.name)")
            print("Description : \(startingRoom.description)")
        } else {
            print("Erreur : Aucune salle de départ trouvée.")
        }
    }
}