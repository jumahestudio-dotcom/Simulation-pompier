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
## Voitures du trafic, fusionnées en un seul maillage. "ecarter" : matériaux supprimés (pièces
## intérieures invisibles) ; "retouches" : plaques et logos peints dans les textures, effacés.
## "rot" : rotation pour mettre l'avant vers -z.
const VOITURES_TRAFIC := {
	"polo": {"f": "2021_volkswagen_polo_plus.glb", "peinture": "carpaint_C1", "rot": PI,
		"noeuds": ["09_car_body_black_plastic_plaslic_SH_0", "10_car_body_metal_chrome_0", "57_trunk_metal_chrome_0", "58_trunk_plus_metal_chrome_0", "58_trunk_plus_plastic_plastic_0", "56_trunk_black_plastic_plastic_0"],
		"ecarter": ["breaks", "plaslic_SH", "tapete", "inner_door", "mirror"],
		"retouches": {"BAD_L": [[Rect2(0.0, 0.0, 0.595, 0.44), Color(0.9, 0.9, 0.88)]]}},
	"tcross": {"f": "2021_volkswagen_t-cross_280_tsi.glb", "peinture": "carpaint", "rot": PI,
		"noeuds": ["15_car_body_metal_chrome_0", "85_trunk_metal_chrome_0", "86_trunk_metal_chrome_0"],
		"ecarter": ["breaks", "carpet", "trunk", "inner_door", "mirror"],
		"retouches": {"BADG": [[Rect2(0.0, 0.0, 0.545, 0.3), Color(0.9, 0.9, 0.88)], [Rect2(0.612, 0.47, 0.098, 0.1), Color(0.05, 0.05, 0.06)]]}},
}
## Fichiers qui reçoivent des niveaux de détail au chargement.
const LOD := ["skoda_kodiaq_2024.glb", "skoda_octavia_combi_2024.glb"]
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
			if nom in LOD:
				# Niveaux de détail : les modèles très fins (voitures) se simplifient au loin
				for gm in etat.get_meshes():
					var im: ImporterMesh = (gm as GLTFMesh).mesh
					if im != null:
						im.generate_lods(25.0, 60.0, [])
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


# ---------------------------------------------------------------------------
# Modèles fusionnés : tout le fichier devient un seul maillage (une surface par matériau),
# avec niveaux de détail. Beaucoup plus léger à afficher qu'une scène de centaines de nœuds.
# ---------------------------------------------------------------------------

static var _fusions := {}


## "ecarter" : débuts de noms de matériaux à supprimer (intérieur invisible, logos...).
## "noeuds" : noms exacts de pièces à supprimer (logos en relief, inscriptions).
## "retouches" : {début de nom de matériau: [Rect2 en fraction de texture, couleur]} pour effacer
## une inscription ou un logo peint dans la texture.
## Renvoie {"mesh": Mesh, "aabb": AABB, "mats": [noms des matériaux, dans l'ordre des surfaces]} ou {}.
static func fusion(nom: String, garder: String = "", ecarter: Array = [], retouches: Dictionary = {}, noeuds: Array = [], lod: bool = true) -> Dictionary:
	var cle := nom + "|" + garder + "|" + str(ecarter) + str(noeuds)
	if _fusions.has(cle):
		return _fusions[cle]
	var res := {}
	var o := instance(nom, garder)
	if o != null:
		var outils := {}     # nom de matériau -> SurfaceTool
		var mats := {}
		for mi in o.find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi
			if not m.visible or m.mesh == null or str(m.name) in noeuds:
				continue
			var t := Transform3D.IDENTITY
			var x: Node = m
			while x != o and x != null:
				t = (x as Node3D).transform * t
				x = x.get_parent()
			for s in m.mesh.get_surface_count():
				if m.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
					continue
				var mat := m.mesh.surface_get_material(s)
				var mn := mat.resource_name if mat != null else "_"
				var refuse := false
				for e in ecarter:
					if mn.begins_with(e):
						refuse = true
						break
				if refuse:
					continue
				if not outils.has(mn):
					var st := SurfaceTool.new()
					outils[mn] = st
					mats[mn] = _retouche(mat, mn, retouches)
				(outils[mn] as SurfaceTool).append_from(m.mesh, s, t)
		var im := ImporterMesh.new()
		var noms: Array = []
		for mn in outils:
			var st: SurfaceTool = outils[mn]
			st.index()
			var arr := st.commit_to_arrays()
			if arr[Mesh.ARRAY_NORMAL] == null:
				continue
			# Données d'animation et canaux personnalisés inutiles pour un objet fixe
			for k in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]:
				arr[k] = null
			im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, mats[mn], mn)
			noms.append(mn)
		if lod:
			im.generate_lods(25.0, 60.0, [])
		var mesh := im.get_mesh()
		res = {"mesh": mesh, "aabb": mesh.get_aabb(), "mats": noms}
		o.free()
	_fusions[cle] = res
	return res


static func _retouche(mat: Material, mn: String, retouches: Dictionary) -> Material:
	for debut in retouches:
		if not mn.begins_with(debut) or not (mat is StandardMaterial3D):
			continue
		var sm: StandardMaterial3D = (mat as StandardMaterial3D).duplicate()
		sm.albedo_texture = _peindre(sm.albedo_texture, retouches[debut], false)
		# Les inscriptions sont souvent aussi dans la texture lumineuse (émission) : on les éteint.
		if sm.emission_enabled and sm.emission_texture != null:
			sm.emission_texture = _peindre(sm.emission_texture, retouches[debut], true)
		return sm
	return mat


static func _peindre(tex: Texture2D, zones: Array, noir: bool) -> Texture2D:
	if tex == null:
		return tex
	var img := tex.get_image()
	if img == null:
		push_warning("Retouche impossible")
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for zone in zones:
		var r: Rect2 = zone[0]
		img.fill_rect(Rect2i(int(r.position.x * w), int(r.position.y * h), int(r.size.x * w), int(r.size.y * h)), Color.BLACK if noir else zone[1])
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Instance d'un modèle fusionné posée au sol, centrée sur "pos". Renvoie le MeshInstance3D ou null.
static func poser_fusion(racine: Node3D, f: Dictionary, pos: Vector3, rot_y: float, s: float = 1.0) -> MeshInstance3D:
	if f.is_empty():
		return null
	var bb: AABB = f["aabb"]
	var mi := MeshInstance3D.new()
	mi.mesh = f["mesh"]
	var b := Basis(Vector3.UP, rot_y) * Basis.from_scale(Vector3.ONE * s)
	var c := bb.get_center()
	mi.transform = Transform3D(b, pos - b * Vector3(c.x, bb.position.y, c.z))
	racine.add_child(mi)
	return mi


static var _peintures := {}


## Voiture du trafic (modèle de Sellier fusionné), avant vers -z, roues à y = 0. null si le fichier manque.
static func voiture_trafic(parent: Node3D, type: String, couleur: Color) -> Node3D:
	var v: Dictionary = VOITURES_TRAFIC[type]
	if not present(v["f"]):
		return null
	var f := fusion(v["f"], "", v["ecarter"], v["retouches"], v["noeuds"])
	var mi := poser_fusion(parent, f, Vector3.ZERO, v["rot"])
	if mi == null:
		return null
	var i: int = (f["mats"] as Array).find(v["peinture"])
	if i >= 0:
		var cle := type + str(couleur)
		if not _peintures.has(cle):
			var base := mi.mesh.surface_get_material(i)
			var p: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
			p.albedo_color = couleur
			p.albedo_texture = null
			p.metallic = 0.35
			p.roughness = 0.32
			_peintures[cle] = p
		mi.set_surface_override_material(i, _peintures[cle])
	return mi


## Pose un objet fusionné à la hauteur voulue (en mètres), centré sur "pos", posé au sol.
## Options : "garder", "ecarter", "noeuds", "retouches", "solide" (boîte de collision), "echelle" (au lieu de la hauteur).
static func objet(racine: Node3D, nom: String, pos: Vector3, rot_y: float, hauteur: float, opt: Dictionary = {}) -> MeshInstance3D:
	if not present(nom):
		return null
	var f := fusion(nom, opt.get("garder", ""), opt.get("ecarter", []), opt.get("retouches", {}), opt.get("noeuds", []))
	if f.is_empty():
		return null
	var bb: AABB = f["aabb"]
	var s: float = opt.get("echelle", hauteur / maxf(bb.size.y, 0.0001))
	var mi := poser_fusion(racine, f, pos, rot_y, s)
	if opt.get("ombre", true) == false:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if opt.get("solide", false):
		var corps := StaticBody3D.new()
		corps.transform = Transform3D(Basis(Vector3.UP, rot_y), pos + Vector3(0, bb.size.y * s * 0.5, 0))
		var cs := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = bb.size * s * float(opt.get("marge", 0.9))
		cs.shape = forme
		corps.add_child(cs)
		racine.add_child(corps)
	return mi
