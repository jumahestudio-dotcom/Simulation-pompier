extends RefCounted
## Décor tiré des modèles 3D de Sellier (lot du 24/11) : érables et bosquets, kiosque à café,
## coffrets électriques, entrepôt et chantier aux Ormeaux, VTU et matériel dans la caserne.
## Chaque modèle est fusionné en un seul maillage avec niveaux de détail. Si un fichier manque,
## l'objet est simplement absent (ou remplacé par sa version dessinée en code).

const Modeles = preload("res://scripts/modeles3d.gd")
const Verdure = preload("res://scripts/verdure.gd")

const ERABLE := "maple_tree.glb"
const BOSQUET := "tree_animate.glb"
const CAFE := "corner_cafe.glb"
const ARMOIRE_ELEC := "electrical_box_-_free.glb"
const BOITIER_ELEC := "electric_box_1_lowpoly.glb"
const ENTREPOT := "small_warehouse.glb"
const CHANTIER := "construction_site_asset_pack.glb"
const GABION := "modular_gabion_fence_element.glb"
const CHAINE := "blocking_the_street_avenue_tool.glb"
const TERRE := "a_pile_of_clay.glb"
const VTU := "frenchfirebrigade_vehicle.glb"
const SAC := "sac_sapeur_pompier_grand_format.glb"
const EXTINCTEUR := "modern_fire_extinguisher.glb"
const LANCE := "hohlstrahlrohr.glb"
const TUYAU := "firefighter_vision_water_attack_hose.glb"

## Érable : on ne garde que l'arbre (pas le disque de gazon fourni avec).
const OPT_ERABLE := {"garder": "SketchUp#2", "ombre": true}
## Fourgon : logo de marque, nom de ville et enjoliveurs effacés dans la texture.
const OPT_VTU := {"solide": true, "retouches": {"Scene_-_Root": [
	[Rect2(0.469, 0.064, 0.158, 0.024), Color(0.36, 0.024, 0.035)],
	[Rect2(0.286, 0.703, 0.156, 0.029), Color(0.31, 0.016, 0.024)],
	[Rect2(0.097, 0.379, 0.032, 0.037), Color(0.08, 0.08, 0.08)],
	[Rect2(0.624, 0.882, 0.022, 0.022), Color(0.4, 0.41, 0.41)]]}}


static func construire(racine: Node3D) -> void:
	_square(racine)
	_tilleuls(racine)
	_ormeaux(racine)
	_caserne(racine)


static func _erable(racine: Node3D, p: Vector3, h: float, rot: float) -> void:
	Modeles.objet(racine, ERABLE, p, rot, h, OPT_ERABLE)


static func _square(racine: Node3D) -> void:
	# Kiosque à café avec sa terrasse, dans le quart nord-est du square
	var k := Vector3(-46.0, 0, 296.0)
	if Modeles.objet(racine, CAFE, k, 0.0, 0.0, {"echelle": 1.0}) != null:
		Verdure.exclure(Rect2(k.x - 6.5, k.z - 4.5, 13.0, 9.0))
		var corps := StaticBody3D.new()
		corps.position = k + Vector3(0, 1.8, -0.9)
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(5.0, 3.6, 2.6)
		cs.shape = bx
		corps.add_child(cs)
		racine.add_child(corps)
	var i := 0
	for p in [Vector3(-27.3, 0, 281.7), Vector3(-21.6, 0, 307.7), Vector3(-122.7, 0, 346.7), Vector3(-96.7, 0, 361.1), Vector3(-62.0, 0, 282.0)]:
		_erable(racine, p, 8.5 + (i % 3) * 0.8, i * 1.3)
		i += 1


static func _tilleuls(racine: Node3D) -> void:
	# Bosquets de trois arbres sur les pelouses entre les immeubles
	for b in [[Vector3(-121.7, 0, -355.0), 0.3], [Vector3(-258.0, 0, -225.0), 2.0], [Vector3(-128.3, 0, -221.7), 4.1]]:
		Modeles.objet(racine, BOSQUET, b[0], b[1], 10.5)
	for p in [Vector3(-160.0, 0, -300.0), Vector3(-240.0, 0, -290.0), Vector3(-300.0, 0, -350.0)]:
		_erable(racine, p, 9.0, p.x)
	# Armoires électriques le long de la rue, boîtiers de comptage près des tours
	for a in [[Vector3(-192.5, 0, -380.0), PI * 0.5], [Vector3(-192.5, 0, -250.0), PI * 0.5]]:
		Modeles.objet(racine, ARMOIRE_ELEC, a[0], a[1], 1.5, {"solide": true})
	for b in [[Vector3(-226.0, 0, -383.0), 0.0], [Vector3(-125.0, 0, -405.0), PI]]:
		Modeles.objet(racine, BOITIER_ELEC, b[0], b[1], 0.9)


static func _ormeaux(racine: Node3D) -> void:
	# Petit entrepôt à côté des cuves
	var e := Vector3(371.5, 0, 83.0)
	if Modeles.objet(racine, ENTREPOT, e, 0.0, 0.0, {"echelle": 1.0, "solide": true, "marge": 0.97}) != null:
		Verdure.exclure(Rect2(e.x - 6.0, e.z - 7.0, 12.0, 14.0))
	# Chantier d'extension en bord de route : matériaux, tas de terre, gabions au fond, chaînes devant
	var c := Vector3(519.0, 0, 21.0)
	if not Modeles.present(CHANTIER):
		return
	Verdure.exclure(Rect2(c.x - 15.0, c.z - 8.0, 30.0, 17.0))
	Modeles.objet(racine, CHANTIER, c, 0.0, 0.0, {"echelle": 0.7, "solide": true, "marge": 0.6})
	Modeles.objet(racine, TERRE, c + Vector3(-10.0, 0, 3.0), 0.4, 0.0, {"echelle": 1.1})
	Modeles.objet(racine, TERRE, c + Vector3(10.5, 0, 4.0), 2.0, 0.0, {"echelle": 0.9})
	for k in 14:
		Modeles.objet(racine, GABION, c + Vector3(-13.0 + k * 2.0, 0, 8.0), 0.0, 1.0)
	for k in 4:
		Modeles.objet(racine, CHAINE, c + Vector3(-10.5 + k * 7.0, 0, -7.6), 0.0, 1.2, {"ombre": false})


static func _caserne(racine: Node3D) -> void:
	# Fourgon VTU garé dans la cour arrière
	Modeles.objet(racine, VTU, Vector3(-240.0, 0, -75.5), PI * 0.5, 0.0, OPT_VTU.merged({"echelle": 0.0088}))
	# Sacs d'intervention près du VSAV, à côté du brancard de rechange
	for k in 3:
		Modeles.objet(racine, SAC, Vector3(-268.3, 0, -45.6 + k * 0.62), PI * 0.5, 0.8)
	# Tuyaux en rouleaux alignés contre le mur et lance posée devant, près du dévidoir
	for k in 5:
		Modeles.objet(racine, TUYAU, Vector3(-215.85, 0, -29.8 + k * 0.15), 0.0, 0.5)
	Modeles.objet(racine, LANCE, Vector3(-216.6, 0, -30.6), PI * 0.5, 0.0, {"echelle": 0.075})
