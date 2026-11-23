# Simulation Sapeur-Pompier — prototype

Jeu de simulation de sapeur-pompier français, fait avec **Godot 4** (gratuit).
Ce premier prototype fait vivre **une garde de sapeur 2e classe** au centre de secours de
**Joué-lès-Tours**, dans un SDIS fictif inspiré de celui d'Indre-et-Loire.

## Comment lancer le jeu (pas à pas)

1. **Télécharger Godot 4.3** (version « Standard », pas « .NET ») :
   https://godotengine.org/download/archive/4.3-stable/
   Sous Windows, prenez « Windows 64-bit ». C'est un fichier zip : faites clic droit puis
   « Extraire tout ». Il n'y a rien à installer : le programme `Godot_v4.3-stable_win64.exe` se lance directement.
2. **Télécharger le jeu** : sur la page GitHub du projet, bouton vert **Code** puis
   **Download ZIP**. Extrayez le zip dans un dossier (par exemple `Documents\simulation-pompier`).
3. **Ouvrir le projet** : lancez Godot. Dans la fenêtre « Gestionnaire de projets »,
   cliquez sur **Importer**, choisissez le fichier `project.godot` qui se trouve dans le dossier du jeu,
   puis **Importer et modifier**. La première ouverture prend quelques secondes.
4. **Jouer** : appuyez sur **F5** (ou le bouton ▶ « Lancer le projet » en haut à droite).
   Pour quitter le jeu, fermez sa fenêtre ou appuyez sur **F8** dans Godot.

Si quelque chose ne marche pas, faites une capture d'écran (de la fenêtre du jeu, ou du panneau
« Sortie » en bas de Godot) et envoyez-la.

## Les commandes

| Touche | Action |
|---|---|
| Z Q S D (ou W A S D, ou les flèches) | Marcher |
| Maj | Courir |
| Souris | Regarder |
| E | Interagir (vestiaire, monter dans l'engin, ARI, lance, escalier, victime…) |
| Clic gauche (maintenu) | Arroser, quand la lance est en main |
| 1 à 7 | Gestes de secours près d'une victime |
| T (maintenu) | Accélérer un trajet |
| N | Faire sonner le prochain appel tout de suite |
| F2 | Tirage des appels : équilibré ou réaliste |
| Échap | Libérer la souris |

## Ce que contient le prototype

- **Un quartier** : un boulevard, des rues, des immeubles en tuffeau aux toits d'ardoise, le Cher et son pont,
  un centre hospitalier, du trafic qui se range au deux-tons.
- **La caserne** de Joué-lès-Tours avec un **VSAV** et un **FPT**, des collègues IA
  (chef de garde, chefs d'agrès, conducteurs, binômes) avec un grade, un rôle, un caractère et un avis sur vous.
- **Trois scénarios** tirés au sort, avec leurs variantes du référentiel :
  - **Malaise à domicile** (diabétique, cardiaque, personne âgée au sol) ;
  - **Malaise ou blessé sur la voie publique** (ivresse, épilepsie, chute de trottinette) ;
  - **Feu d'appartement au 2e étage** (fumée, cage d'escalier enfumée, victime à la fenêtre).
- **Déroulé d'une intervention** : alarme et ticket de départ, habillage, départ (délai mesuré), trajet,
  statuts radio, travail sur place, transport à l'hôpital, retour, **note sur 20** et expérience.
- **Victimes** : 4 fonctions suivies (conscience, ventilation, circulation, température), pas de barre de vie :
  il faut faire le bilan pour lire les constantes. 5 gestes (oxygène, PLS, immobilisation, couverture… ) plus
  la transmission du bilan au médecin régulateur et le brancardage. Les mauvais gestes coûtent des points.
- **Feu** : il grandit pièce par pièce, enfume l'appartement et recule sous la lance. Air de l'ARI limité
  (sifflet de fin de charge), eau de la citerne puis alimentation par le poteau d'incendie.
- La carrière (expérience, nombre d'interventions) est sauvegardée entre deux parties.

## Données

`data/referentiel_pompiers.json` : engins, natures d'intervention, proportions nationales 2024,
départs réflexes, grades et casernes fictives. Le jeu lit ce fichier pour tirer les appels et remplir le ticket.

## Pour les développeurs

- `scripts/main.gd` : déroulé de la garde et des interventions.
- `scripts/monde.gd` : construction du quartier. `scripts/carte.gd` : plan des rues et calcul d'itinéraire.
- `scripts/victime.gd`, `scripts/feu.gd`, `scripts/engin.gd`, `scripts/trafic.gd`, `scripts/collegue.gd`, `scripts/hud.gd`.
- Test automatique des trois scénarios : `godot --headless --path . res://tests/test_auto.tscn`

Tout est original : aucun fichier ni contenu d'un jeu existant n'est utilisé.
