# Mon Projet Swift : Donjon d’Argath

Donjon d’Argath est un jeu d’aventure textuel en ligne de commande, développé en Swift. Vous incarnez un aventurier explorant un donjon mystérieux, résolvant des énigmes, combattant des ennemis, et collectant des fragments pour assembler l’Œil d’Argath. Ce README explique comment configurer, démarrer et jouer au jeu dans un environnement Docker.
Prérequis

Docker : Assurez-vous que Docker est installé sur votre machine. Téléchargez-le depuis docker.com si nécessaire.
Git : Pour cloner le dépôt du jeu (optionnel, si le code n’est pas déjà local).
Un terminal compatible avec les caractères Unicode (pour un affichage optimal de la carte).

# Configuration
1. Cloner le Dépôt

2. Construire l’Image Docker
Le jeu est conteneurisé pour garantir une exécution cohérente. Construisez l’image Docker à partir du répertoire contenant le Dockerfile 

3. Lancer le Conteneur
Démarrez un conteneur interactif à partir de l’image construite. Montez le répertoire local pour persister les fichiers de sauvegarde (


# Démarrer le Jeu

Une fois dans le conteneur, compilez et exécutez le jeu :
swift build
swift run

Vous verrez le menu principal :
----------------------------------------------------
BIENVENUE DANS LE DONJON D’ARGATH
----------------------------------------------------
1. Commencer une nouvelle partie
2. Charger une partie
3. Quitter le jeu
----------------------------------------------------
Entrez un numéro (1, 2 ou 3) :


Nouvelle partie : Entrez 1, puis saisissez un nom pour votre personnage.
Charger une partie : Entrez 2, puis sélectionnez un joueur existant.
Quitter : Entrez 3 pour sortir.

# Comment Jouer

Objectifs
Votre mission principale est de compléter la quête Les Fragments de l’Œil :

Explorez les salles du donjon (Entrée, Salle des Statues, Bibliothèque Oubliée, etc.).
Résolvez des énigmes pour collecter des objets (torche, clé, fragments).
Affrontez des ennemis, comme le golem dans le Sanctuaire Brisé.
Rassemblez trois fragments (fragment_1, fragment_2, fragment_3) et la connaissance pour créer l’Œil d’Argath.
Utilisez l’Œil d’Argath pour déverrouiller la Sortie et terminer le jeu.

Chaque salle contient des énigmes, des objets, ou des personnages (ermite, scribe, prêtre) qui fournissent des indices. Les chapitres (ex. : Le Gardien du Fragment) guident votre progression.

# Commandes Disponibles
Dans le jeu, entrez les commandes suivantes (en minuscules) :

aller <direction>
Se déplacer vers une salle dans la direction indiquée (nord, sud, est, ouest). ex : aller nord

regarder
Afficher la description de la salle actuelle, les sorties, les personnages, et les dangers. ex: regarder

prendre <objet>
Ramasser un objet dans la salle. ex: prendre torche

utiliser <objet>
Utiliser un objet (ex. : clé pour déverrouiller une porte). ex: utiliser cle

résoudre
Résoudre l’énigme de la salle actuelle en entrant une réponse. ex: résoudre (puis écho)

combattre <ennemi>
Affronter un ennemi (ex. : golem, nécessite un objet spécifique comme l’amulette). ex: combattre golem

combiner <objets>
Combiner plusieurs objets pour créer un nouvel item (ex. : fragments). ex: combiner fragment_1,fragment_2,fragment_3,connaissance

afficher carte
Afficher une carte du donjon avec les salles visitées et les connexions.

parler <personnage>
Interagir avec un personnage pour obtenir des indices. ex: parler pretre

attendre
Passer un tour, avançant le temps (affecte les énigmes à durée limitée).

sauvegarder
Sauvegarder votre progression dans save.json.

quitter
Retourner au menu principal (sauvegardez avant).
quitter


# Exemple de Gameplay

Vous commencez dans l’Entrée du Donjon.
Entrez prendre torche pour ramasser la torche.
Entrez utiliser torche pour révéler l’énigme (puzzle4).
Entrez résoudre et saisissez lumière pour obtenir la clé.
Entrez aller est pour atteindre la Salle Verrouillée, puis utiliser cle.
Continuez à explorer, résolvez des énigmes, et collectez les fragments.

# Conseils

Consultez la carte régulièrement (afficher carte) pour visualiser les connexions.
Parlez aux personnages (ex. : parler ermite) pour des indices.
Sauvegardez souvent (sauvegarder) pour éviter de perdre votre progression.
Certaines énigmes ont une limite de temps. Si le temps est écoulé, utilisez la réponse alternative amulette (ex. : dans la Chambre des Échos).

# Dépannage

Erreur de compilation : Assurez-vous que Swift est correctement configuré dans l’image Docker. Vérifiez le Dockerfile.
Fichier save.json corrompu : Supprimez /app/Resources/save.json et recommencez une nouvelle partie.
Affichage de la carte incorrect : Utilisez un terminal supportant Unicode (ex. : iTerm2, Windows Terminal).

# Contribuer
Pour contribuer au développement :

Forkez le dépôt.
Créez une branche (git checkout -b feature/nouvelle-fonction).
Soumettez une pull request avec une description claire.

