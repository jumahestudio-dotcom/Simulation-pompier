extends RefCounted
## Modèles 3D personnels de Sellier (fichiers .glb copiés dans le dossier modeles/, jamais publiés).
## Chaque modèle est chargé une fois, puis recopié. S'il manque, la fonction renvoie null
## et la ville garde ses bâtiments dessinés en code.

const DOSSIER := "res://modeles/"

## Immeubles du centre ancien. Façade principale vers +z dans le fichier ; x0..x1 = largeur de façade,
## zf = plan de la façade, zb = fond, h = hauteur. "angle" : immeuble d'angle (deuxième façade côté +x).
const IMMEUBLES := [
	{"f": "angers_shop_2_france.glb", "x0": -2.0, "x1": 8.0, "zf": 7.3, "zb": -7.99, "h": 15.2},
	{"f": "troyes_shop_8_france.glb", "x0": -6.15, "x1": 8.29, "zf": 8.14, "zb": -8.3, "h": 16.6},
]
const BARRE := "soviet_panelki__voxel_style_apartment_buildings.glb"   # on ne garde que "Apartment" (version de jour)
const TOUR := "modern_night_building_game-ready.glb"
const BUREAUX := "fd0fcff7053d4d9f8829320a30d7087e.glb"
const CUVE := "simple_industrial_storage_tank.glb"
const GAZ := "propane_and_gas_tanks_set_-_game_ready.glb"
const MAISON := "tramain_house_1_france.glb"
const POTEAU := "damaged_firehydrant.glb"
const ARBRE := "tree_low_poly_lowpoly.glb"   # deux arbres : "Tree 1" et "Tree 2"
const PLANTES := "scanned_plants_and_grass_free_download.glb"   # massifs : "Plants*#6" à "Plants*#16"
const RUE := "street_objects_pack_1_revamped.glb"
## Objets du pack de mobilier urbain (numéro de l'objet sous RootNode)
const BANC_ROT := 0.0   # rotation à ajouter pour que le banc ait le dossier côté immeubles
const MOBILIER := {"banc_bois": "RootNode#42", "banc_metal": "RootNode#46", "poubelle": "RootNode#26", "jardiniere": "RootNode#58", "poteau": "RootNode#11"}

## Voitures : fichier, matériaux de peinture, matériaux et nœuds à cacher (logos, noms, plaques).
## L'avant des fichiers est vers -x : on les tourne d'un quart de tour.
const VOITURES := {
	"kodiaq": {"f": "skoda_kodiaq_2024.glb", "peinture": "e_Carpaint", "mats": ["lICENSE", "e_chrome_Unique_Dark", "Texts_Texture", "text_ui"], "noeuds": []},
	"octavia": {"f": "skoda_octavia_combi_2024.glb", "peinture": "e_Carpaint", "mats": ["Material.006", "E_Chrome.011", "Texts_Texture", "text_ui"], "noeuds": ["Object_47"]},
}
const ANGLE := {"f": "bordeaux_flat_2_corner_france.glb", "x0": -11.5, "x1": 15.3, "zf": 7.3, "zb": -3.9, "h": 18.6, "angle": true}

static var _cache := {}
static var _boites := {}


static func present(nom: String) -> bool:
	return FileAccess.file_exists(DOSSIER + nom)


## Le modèle d'origine (hors scène), chargé une seule fois.
static func _original(nom: String) -> Node3D:
	if _cache.has(nom):
		return _cache[nom]
	var n: Node3D = null
	if present(nom):
		var doc := GLTFDocument.new()
		var etat := GLTFState.new()
		if doc.append_from_file(DOSSIER + nom, etat) == OK:
			n = doc.generate_scene(etat)
		else:
			push_warning("Modèle illisible : " + nom)
	_cache[nom] = n
	return n


## Une copie prête à placer, ou null si le fichier n'est pas là.
## "garder" : ne conserver que ce nœud (et pas ses voisins), pour un fichier qui contient plusieurs objets.
static func instance(nom: String, garder: String = "") -> Node3D:
	var cle := nom + "|" + garder
	if not _cache.has(cle):
		var o := _original(nom)
		if o != null and garder != "":
			o = o.duplicate()
			var g: Node = null
			if garder.contains("#"):
				# "parent#numéro" : garder l'enfant numéro N du nœud "parent" (noms illisibles dans le fichier)
				var morceaux := garder.split("#")
				var par := o.find_child(morceaux[0], true, false)
				if par != null and int(morceaux[1]) < par.get_child_count():
					g = par.get_child(int(morceaux[1]))
			else:
				g = o.find_child(garder, true, false)
			if g != null:
				for frere in g.get_parent().get_children():
					if frere != g:
						frere.get_parent().remove_child(frere)
						frere.free()
		_cache[cle] = o
	var o2: Node3D = _cache[cle]
	if o2 == null:
		return null
	return o2.duplicate()


## Boîte englobante d'un modèle, dans son propre repère.
static func boite(nom: String, garder: String = "") -> AABB:
	var cle := nom + "|" + garder
	if _boites.has(cle):
		return _boites[cle]
	var o := instance(nom, garder)
	var bb := AABB()
	if o != null:
		var premier := true
		for mi in o.find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi
			var t := Transform3D.IDENTITY
			var x: Node = m
			while x != o and x != null:
				t = (x as Node3D).transform * t
				x = x.get_parent()
			var b: AABB = t * m.get_aabb()
			if premier:
				bb = b
				premier = false
			else:
				bb = bb.merge(b)
		o.free()
	_boites[cle] = bb
	return bb


## Pose un modèle posé au sol, centré sur "pos", tourné de "rot_y", à l'échelle "s", avec un volume de collision.
static func poser(racine: Node3D, nom: String, pos: Vector3, rot_y: float, s: float, garder: String = "", solide: bool = true) -> Node3D:
	var inst := instance(nom, garder)
	if inst == null:
		return null
	var bb := boite(nom, garder)
	var b := Basis(Vector3.UP, rot_y) * Basis.from_scale(Vector3.ONE * s)
	var c := bb.get_center()
	inst.transform = Transform3D(b, pos - b * Vector3(c.x, bb.position.y, c.z))
	racine.add_child(inst)
	if solide:
		var corps := StaticBody3D.new()
		corps.transform = Transform3D(Basis(Vector3.UP, rot_y), pos + Vector3(0, bb.size.y * s * 0.5, 0))
		var cs := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = bb.size * s * 0.95
		cs.shape = forme
		corps.add_child(cs)
		racine.add_child(corps)
	return inst


static func immeubles_disponibles() -> Array:
	var l: Array = []
	for m in IMMEUBLES:
		if present(m["f"]):
			l.append(m)
	return l


static func largeur(m: Dictionary) -> float:
	return float(m["x1"]) - float(m["x0"])


static func profondeur(m: Dictionary) -> float:
	return float(m["zf"]) - float(m["zb"])


## Pose un immeuble : "pied" = milieu de la façade au sol, "n" = direction de la rue (normale de façade).
## "miroir" retourne le bâtiment de gauche à droite (pour mettre l'angle du bon côté).
static func poser_immeuble(racine: Node3D, m: Dictionary, pied: Vector3, n: Vector3, s: float, miroir: bool) -> bool:
	var inst := instance(m["f"])
	if inst == null:
		return false
	var rot := atan2(n.x, n.z)
	var b := Basis(Vector3.UP, rot) * Basis.from_scale(Vector3(-s if miroir else s, s, s))
	var cx: float = (float(m["x0"]) + float(m["x1"])) * 0.5
	inst.transform = Transform3D(b, pied - b * Vector3(cx, 0, float(m["zf"])))
	racine.add_child(inst)
	# Volume de collision (sans échelle négative)
	var corps := StaticBody3D.new()
	var br := Basis(Vector3.UP, rot)
	var centre_l := Vector3(cx, float(m["h"]) * 0.5, (float(m["zf"]) + float(m["zb"])) * 0.5) - Vector3(cx, 0, float(m["zf"]))
	corps.transform = Transform3D(br, pied + br * (centre_l * s))
	var cs := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(largeur(m) - 0.3, float(m["h"]), profondeur(m) - 0.3) * s
	cs.shape = forme
	corps.add_child(cs)
	racine.add_child(corps)
	return true


## Direction, dans le monde, du côté "+x" du modèle une fois tourné vers la rue.
static func cote_x(n: Vector3) -> Vector3:
	return Basis(Vector3.UP, atan2(n.x, n.z)) * Vector3.RIGHT


static var _invisible: StandardMaterial3D = null


## Pose une voiture de modèle "type" (sans logo), avant tourné selon "angle" (0 = avant vers -z).
static func voiture(racine: Node3D, type: String, pos: Vector3, angle: float, couleur: Color) -> Node3D:
	var v: Dictionary = VOITURES[type]
	var inst := poser(racine, v["f"], pos, angle - PI * 0.5, 1.0)
	if inst == null:
		return null
	if _invisible == null:
		_invisible = StandardMaterial3D.new()
		_invisible.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_invisible.albedo_color = Color(0, 0, 0, 0)
	var peinture: StandardMaterial3D = null
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		if str(m.name) in v["noeuds"]:
			m.visible = false
			continue
		var caches := 0
		var nb := m.mesh.get_surface_count()
		for s in nb:
			var mat := m.mesh.surface_get_material(s)
			if mat == null:
				continue
			var nom := mat.resource_name
			for c in v["mats"]:
				if nom.begins_with(c):
					m.set_surface_override_material(s, _invisible)
					caches += 1
					break
			if nom.begins_with(v["peinture"]) and mat is StandardMaterial3D:
				if peinture == null:
					peinture = (mat as StandardMaterial3D).duplicate()
					peinture.albedo_color = couleur
					peinture.albedo_texture = null
				m.set_surface_override_material(s, peinture)
		if caches == nb:
			m.visible = false
	return inst
