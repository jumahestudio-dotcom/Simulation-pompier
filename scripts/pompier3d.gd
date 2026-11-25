## Pompier en 3D d'après le modèle de Sellier (firefighter.glb, squelette Mixamo).
## Même interface que corps.gd (construire, equiper, animer), pour que collegue.gd
## puisse utiliser l'un ou l'autre. Si le fichier manque, disponible() renvoie false
## et l'on garde le corps dessiné en code.
##
## Le modèle d'origine tient une lance en position d'attaque : on retire la lance,
## le tuyau, l'eau et le poteau, on repart de la pose de référence (bras en croix,
## lue dans le « skin » du fichier) et on règle nous-mêmes chaque articulation :
## debout, bras le long du corps, puis la marche (hanches, genoux, épaules, coudes).
##
## Tenue F1 (sans casque) : on retire la cagoule et l'on pose la tête dessinée en
## code (visage, coiffure et couleur de peau propres à chaque collègue).
## Tenue de feu : casque, cagoule, masque et appareil respiratoire du modèle.
extends Node3D

const M = preload("res://scripts/modeles3d.gd")
const Corps = preload("res://scripts/corps.gd")
const FICHIER := "firefighter.glb"

# Pièces du modèle (nœuds parents des maillages, noms d'origine)
const P_CASQUE := ["Kaska"]
const P_CAGOULE := ["Balaklava"]
const P_MASQUE := ["GasMask"]
const P_ARI := ["breath_system", "Manometr", "Remen_balon"]
static var BAISSE_BRAS := 0.6
const P_RETIRER := ["FireHose", "FireHydrant"]

var tenue: Dictionary = {}
var _sk: Skeleton3D
var _modele: Node3D
var _os := {}            # nom court -> index d'os
var _bind := {}          # index -> Transform3D global de la pose de référence (bras en croix)
var _local := {}         # index -> Basis locale de la pose de référence
var _ordre: Array = []   # os triés parents d'abord
var _pieces := {}        # "casque", "cagoule", "masque", "ari" -> Array de MeshInstance3D
var _tete_code: Node3D = null
var _casque_on := false
var _ari_on := false
var _pas := 0.0
var _t := 0.0
var _vu := false


static func disponible() -> bool:
	return M.present(FICHIER)


## Personnages Mixamo envoyés par Sellier pour les tenues hors intervention
## (fichiers .fbx d'origine, copiés dans modeles/mixamo/ sans les renommer).
## Chaque pièce de vêtement est un maillage à part : on la teint aux couleurs SDIS37.
const DOSSIER_CIVILS := "res://modeles/mixamo/"
const CIVILS := {
	"station": {"M": "Ch01_nonPBR.fbx", "F": "Ch22_nonPBR.fbx"},
	"sport": {"M": "Ch38_nonPBR.fbx", "F": "Ch37_nonPBR.fbx"},
}
## Teintes par pièce (fin du nom du maillage) : [couleur, intensité].
const TEINTES_CIVILES := {
	"station": {"Shirt": [Color(0.12, 0.16, 0.3), 1.0], "Pants": [Color(0.09, 0.11, 0.2), 1.6], "Sneakers": [Color(0.05, 0.05, 0.06), 1.0]},
	"sport": {"Shirt": [Color(0.7, 0.07, 0.07), 1.0], "Shorts": [Color(0.1, 0.13, 0.26), 1.0], "Socks": [Color(0.1, 0.13, 0.26), 1.0], "Pants": [Color(0.1, 0.12, 0.22), 2.0]},
}

var civil := false
var fichier := FICHIER
var _baisse := BAISSE_BRAS
const ANGLE_BRAS := 1.32   # bras le long du corps : angle sous l'horizontale (rad)


## Le fichier Mixamo à utiliser pour ce moment et ce sexe, ou "" s'il n'y en a pas.
static func fichier_civil(contexte_voulu: String, sexe: String) -> String:
	if not CIVILS.has(contexte_voulu):
		return ""
	var f: String = CIVILS[contexte_voulu].get(sexe, "")
	return f if f != "" and FileAccess.file_exists(DOSSIER_CIVILS + f) else ""


static var _fbx := {}


## Charge un .fbx au moment de l'exécution (le dossier n'est pas importé par l'éditeur).
static func _instance_fbx(nom: String) -> Node3D:
	if not _fbx.has(nom):
		var r: Node3D = null
		var doc := FBXDocument.new()
		var etat := FBXState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(DOSSIER_CIVILS + nom), etat) == OK:
			r = doc.generate_scene(etat)
			# Les maillages arrivent « à importer » : on les transforme en maillages affichables.
			for im in r.find_children("*", "ImporterMeshInstance3D", true, false):
				var mi := MeshInstance3D.new()
				var par: Node = im.get_parent()
				var nom_mi := String(im.name)
				mi.mesh = (im as ImporterMeshInstance3D).mesh.get_mesh()
				mi.skin = (im as ImporterMeshInstance3D).skin
				mi.transform = (im as ImporterMeshInstance3D).transform
				par.remove_child(im)
				im.free()
				mi.name = nom_mi
				par.add_child(mi)
				mi.skeleton = NodePath("..") if par is Skeleton3D else NodePath("")
			for n in r.find_children("*", "", true, false):
				n.owner = r
		_fbx[nom] = r
	var o: Node3D = _fbx[nom]
	return null if o == null else o.duplicate()


func construire(p_tenue: Dictionary, p_fichier: String = "") -> void:
	tenue = p_tenue
	if p_fichier != "":
		civil = true
		fichier = p_fichier
		_modele = _instance_fbx(p_fichier)
	else:
		_modele = M.instance(FICHIER)
	if _modele == null:
		return
	add_child(_modele)
	# Le modèle regarde vers +z : on le tourne pour que l'avant soit vers -z, comme corps.gd.
	_modele.rotation.y = PI
	for ap in _modele.find_children("*", "AnimationPlayer", true, false):
		ap.get_parent().remove_child(ap)
		ap.free()
	for nom in P_RETIRER:
		var n := _trouver(nom)
		if n != null:
			n.get_parent().remove_child(n)
			n.free()
	_sk = _modele.find_children("*", "Skeleton3D", true, false)[0]
	_pieces = {"casque": _maillages(P_CASQUE), "cagoule": _maillages(P_CAGOULE), "masque": _maillages(P_MASQUE), "ari": _maillages(P_ARI),
		"veste": _maillages(["Kurtka"]), "pantalon": _maillages(["Shtani"]), "gants": _maillages(["FireGloves"]), "ceinture": _maillages(["Poyas"]), "bottes": _maillages(["Ботинки"])}
	for mi in _sk.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_preparer_os()
	if civil:
		_regler_civil()
	if not civil:
		_poser_casque_f1()
		_preparer_tete()
	var taille: float = float(tenue.get("taille", 1.0)) * float(tenue.get("corpulence", 1.0)) * 0.5 + 0.5
	scale = Vector3.ONE * clampf(taille, 0.96, 1.05)
	equiper(false, false)
	if not civil:
		habiller(String(tenue.get("contexte", "intervention")))
	animer(0.0, 0.0)


func _trouver(debut: String) -> Node:
	for n in _modele.find_children("*", "", true, false):
		if String(n.name).begins_with(debut):
			return n
	return null


func _maillages(debuts: Array) -> Array:
	var r: Array = []
	for mi in _modele.find_children("*", "MeshInstance3D", true, false):
		# Dans le fichier, chaque maillage « Object_N » est rangé à part sous le squelette ;
		# on le reconnaît par son nœud d'origine, gardé dans le nom de son maillage d'attache.
		var cle := String(mi.get_meta("piece", ""))
		if cle == "":
			cle = _piece_de(mi)
			mi.set_meta("piece", cle)
		for d in debuts:
			if cle.begins_with(d):
				r.append(mi)
	return r


## Les maillages du fichier s'appellent Object_10, Object_11… : on retrouve la pièce
## (casque, masque…) grâce à la correspondance relevée dans le fichier d'origine.
const PIECES := {
	"Object_10": "Balaklava", "Object_11": "Balaklava", "Object_13": "breath_system",
	"Object_15": "FireGloves", "Object_17": "FireGloves", "Object_19": "GasMask", "Object_20": "GasMask",
	"Object_22": "Kaska", "Object_23": "Kaska", "Object_25": "Kurtka", "Object_27": "Manometr",
	"Object_29": "Ботинки", "Object_31": "Poyas", "Object_33": "Remen_balon", "Object_35": "Shtani",
}


func _piece_de(mi: Node) -> String:
	return String(PIECES.get(String(mi.name), String(mi.get_parent().name)))


# ---------------------------------------------------------------------------
# Squelette
# ---------------------------------------------------------------------------

const OS_UTILES := {
	"hanches": "Hips", "dos": "Spine", "dos1": "Spine1", "dos2": "Spine2", "cou": "Neck", "tete": "Head",
	"cuisse_g": "LeftUpLeg", "genou_g": "LeftLeg", "pied_g": "LeftFoot", "orteils_g": "LeftToeBase",
	"cuisse_d": "RightUpLeg", "genou_d": "RightLeg", "pied_d": "RightFoot", "orteils_d": "RightToeBase",
	"clavicule_g": "LeftShoulder", "bras_g": "LeftArm", "avbras_g": "LeftForeArm", "main_g": "LeftHand",
	"clavicule_d": "RightShoulder", "bras_d": "RightArm", "avbras_d": "RightForeArm", "main_d": "RightHand",
}


## « mixamorig_LeftArm_12 » ou « mixamorig12_LeftArm » -> « LeftArm ».
static func _os_de(n: String) -> String:
	if not n.begins_with("mixamorig"):
		return ""
	var reste := n.substr(n.find("_") + 1)
	var bouts := reste.split("_")
	if bouts.size() > 1 and bouts[-1].is_valid_int():
		bouts.remove_at(bouts.size() - 1)
	return "_".join(bouts)


func _preparer_os() -> void:
	for i in _sk.get_bone_count():
		var n := _sk.get_bone_name(i)
		for cle in OS_UTILES:
			if _os_de(n) == OS_UTILES[cle]:
				_os[cle] = i
	# Pose de référence (bras en croix, face à +z) : l'inverse des « bind poses » du skin.
	var skin: Skin = null
	for mi in _sk.find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).skin != null:
			skin = (mi as MeshInstance3D).skin
			break
	var glob := {}
	if skin != null:
		for b in skin.get_bind_count():
			var os: int = skin.get_bind_bone(b)
			if os < 0:
				os = _sk.find_bone(skin.get_bind_name(b))
			if os >= 0:
				glob[os] = skin.get_bind_pose(b).affine_inverse()
	# Os sans « bind » (racine, bouts de doigts) : on garde la pose du fichier.
	var restes := {}
	for i in _sk.get_bone_count():
		restes[i] = _sk.get_bone_global_rest(i)
	_ordre = []
	var vus := {}
	while _ordre.size() < _sk.get_bone_count():
		for i in _sk.get_bone_count():
			if vus.has(i):
				continue
			var p := _sk.get_bone_parent(i)
			if p < 0 or vus.has(p):
				vus[i] = true
				_ordre.append(i)
	for i in _ordre:
		var g: Transform3D = glob.get(i, Transform3D())
		var p := _sk.get_bone_parent(i)
		if not glob.has(i):
			# Pas de pose de référence : on suit le parent avec la transformation locale du fichier
			g = (_bind[p] if p >= 0 else Transform3D()) * _sk.get_bone_rest(i)
		_bind[i] = g
		var gp: Transform3D = _bind[p] if p >= 0 else Transform3D()
		var l: Transform3D = gp.affine_inverse() * g
		_local[i] = l.basis.orthonormalized()
		_sk.set_bone_pose_position(i, l.origin)
		_sk.set_bone_pose_rotation(i, _local[i].get_rotation_quaternion())
		_sk.set_bone_pose_scale(i, Vector3.ONE)
	# Pieds au sol : la plante des bottes est à y = 0 dans la pose de référence ?
	var y_pied := INF
	for cle in ["orteils_g", "orteils_d", "pied_g", "pied_d"]:
		if _os.has(cle):
			y_pied = minf(y_pied, (_bind[_os[cle]] as Transform3D).origin.y)
	_y_sol = y_pied - 0.04   # épaisseur de la semelle sous l'os des orteils
	var tr := Transform3D()
	var n: Node = _sk
	while n != null and n != _modele:
		tr = (n as Node3D).transform * tr
		n = n.get_parent()
	_echelle = tr.basis.get_scale().y


var _y_sol := 0.0
var _echelle := 1.0   # du repère du squelette à celui du personnage


## Tourne l'os i de la rotation q (exprimée dans le repère du personnage) par rapport à sa pose de référence.
func _tourner(cle: String, q: Basis) -> void:
	if not _os.has(cle):
		return
	var i: int = _os[cle]
	var bg: Basis = (_bind[i] as Transform3D).basis.orthonormalized()
	var b: Basis = _local[i] * (bg.inverse() * q * bg)
	_sk.set_bone_pose_rotation(i, b.get_rotation_quaternion())


func _rot(axe: Vector3, a: float) -> Basis:
	return Basis(axe, a)


# ---------------------------------------------------------------------------
# Casque, cagoule, tête
# ---------------------------------------------------------------------------

## Casque F1 blanc (le modèle a un casque doré, peu courant en France).
func _poser_casque_f1() -> void:
	for mi in _pieces["casque"]:
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var mat := m.get_active_material(s)
			if mat is StandardMaterial3D and not (mat as StandardMaterial3D).transparency:
				var n := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				n.albedo_color = Color(1.7, 1.72, 1.75)
				n.albedo_texture = _gris(n.albedo_texture)
				n.metallic = 0.3
				n.roughness = 0.35
				m.set_surface_override_material(s, n)


static var _gris_cache := {}


## Version désaturée d'une texture (le doré devient gris clair).
static func _gris(t: Texture2D) -> Texture2D:
	if t == null:
		return null
	if _gris_cache.has(t):
		return _gris_cache[t]
	var img := t.get_image()
	if img == null:
		return t
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var donnees := img.get_data()
	for k in range(0, donnees.size(), 4):
		var l := int(donnees[k] * 0.3 + donnees[k + 1] * 0.55 + donnees[k + 2] * 0.15)
		donnees[k] = l
		donnees[k + 1] = l
		donnees[k + 2] = mini(255, l + 3)
	var img2 := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, donnees)
	img2.generate_mipmaps()
	var r := ImageTexture.create_from_image(img2)
	_gris_cache[t] = r
	return r


## Tête dessinée en code (visage, cheveux) accrochée à l'os de la tête, pour la tenue F1.
func _preparer_tete() -> void:
	if not _os.has("tete") or not tenue.has("peau"):
		return
	var c := Corps.new()
	c.construire(tenue)
	var t: Node3D = c._tete
	t.get_parent().remove_child(t)
	c.free()
	var att := BoneAttachment3D.new()
	att.bone_idx = _os["tete"]
	_sk.add_child(att)
	var pivot := Node3D.new()
	att.add_child(pivot)
	# Repère de l'os de la tête -> repère du personnage (y vers le haut, avant vers +z dans le modèle)
	var bg: Basis = (_bind[_os["tete"]] as Transform3D).basis.orthonormalized()
	pivot.basis = bg.inverse() * Basis(Vector3.UP, PI)
	pivot.add_child(t)
	t.position = Vector3(0, -0.055, -0.005)
	t.scale = Vector3.ONE * 1.02
	_tete_code = t
	for n in t.get_children():
		# Casque et masque dessinés en code : jamais visibles (on montre ceux du modèle).
		if n is Node3D and n.get_child_count() > 0 and not (n is MeshInstance3D):
			n.queue_free()


# ---------------------------------------------------------------------------
# Tenues selon le moment (d'après les modèles SDIS37 de Sellier)
# ---------------------------------------------------------------------------

## Couleurs des tenues, relevées sur les modèles SDIS37 (Femme_*_SDIS37_V2.glb).
## veste / pantalon : teinte appliquée sur la texture du modèle (plis et coutures gardés) ;
## null = texture d'origine (tenue d'intervention F1). gants : false = rangés.
const TENUES := {
	"station": {"bottes": Color(0.04, 0.04, 0.045), "veste": Color(0.11, 0.15, 0.27), "pantalon": Color(0.1, 0.13, 0.22), "gants": false, "gilet": false},
	"sport": {"bottes": Color(0.04, 0.04, 0.045), "veste": Color(0.62, 0.07, 0.07), "pantalon": Color(0.1, 0.13, 0.22), "gants": false, "gilet": false},
	"ceremonie": {"bottes": Color(0.02, 0.02, 0.025), "veste": Color(0.06, 0.08, 0.16), "pantalon": Color(0.06, 0.08, 0.16), "gants": Color(0.95, 0.95, 0.93), "gilet": false},
	"intervention": {"bottes": null, "veste": null, "pantalon": null, "gants": true, "gilet": false},
	"secours_routier": {"bottes": null, "veste": null, "pantalon": null, "gants": true, "gilet": true},
	"incendie": {"bottes": null, "veste": null, "pantalon": null, "gants": true, "gilet": false},
}

var contexte := ""
var _gilet: Node3D = null


## Change de tenue : "station" (tenue de caserne), "sport", "ceremonie", "intervention" (F1),
## "secours_routier" (F1 + gilet haute visibilité), "incendie" (tenue de feu, casque).
func habiller(c: String) -> void:
	if civil:
		_teindre_civil(c)
		return
	if not TENUES.has(c) or _sk == null:
		return
	contexte = c
	var t: Dictionary = TENUES[c]
	_teindre("veste", t["veste"])
	_teindre("pantalon", t["pantalon"])
	_teindre("bottes", t["bottes"])
	var g = t["gants"]
	_montrer("gants", not (g is bool and g == false))
	_teindre("gants", g if g is Color else null)
	_montrer("ceinture", c in ["intervention", "incendie"])
	if t["gilet"] and _gilet == null:
		_poser_gilet()
	if _gilet != null:
		_gilet.visible = t["gilet"]


func _teindre(cle: String, couleur) -> void:
	for mi in _pieces.get(cle, []):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			if couleur == null:
				m.set_surface_override_material(s, null)
			else:
				m.set_surface_override_material(s, _mat_teint(m.mesh.surface_get_material(s), couleur))


## Personnage Mixamo : bras en T dans le fichier, on calcule de combien les baisser ;
## peau et vêtements opaques (seuls cheveux et cils gardent leur transparence).
func _regler_civil() -> void:
	if _os.has("bras_g") and _os.has("avbras_g"):
		var a: Vector3 = (_bind[_os["bras_g"]] as Transform3D).origin
		var b: Vector3 = (_bind[_os["avbras_g"]] as Transform3D).origin
		var d := b - a
		var sous := atan2(-d.y, Vector2(d.x, d.z).length())
		_baisse = ANGLE_BRAS - sous
	for mi in _modele.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var piece := String(m.name).get_slice("_", 1)
		if piece in ["Hair", "Eyelashes", "Eyeleashes"]:
			continue
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				var n := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				n.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				m.mesh.surface_set_material(s, n)


func _teindre_civil(c: String) -> void:
	contexte = c
	var t: Dictionary = TEINTES_CIVILES.get(c, {})
	for mi in _modele.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var piece := String(m.name).get_slice("_", 1)
		for s in m.mesh.get_surface_count():
			if t.has(piece):
				var mat := _mat_teint(m.mesh.surface_get_material(s), t[piece][0])
				if mat is StandardMaterial3D:
					mat = (mat as StandardMaterial3D).duplicate()
					(mat as StandardMaterial3D).albedo_color = (t[piece][0] as Color) * float(t[piece][1])
					(mat as StandardMaterial3D).albedo_color.a = 1.0
				m.set_surface_override_material(s, mat)
			else:
				m.set_surface_override_material(s, null)


static var _teints := {}


## Matériau d'origine passé en niveaux de gris puis teinté : on garde les plis, les coutures
## et les bandes (plus claires), dans la couleur de la tenue.
static func _mat_teint(origine: Material, couleur: Color) -> Material:
	var cle := [origine, couleur]
	if _teints.has(cle):
		return _teints[cle]
	var r: Material = origine
	if origine is StandardMaterial3D:
		var n := (origine as StandardMaterial3D).duplicate() as StandardMaterial3D
		if couleur.get_luminance() > 0.7:
			# Teinte claire (gants blancs de cérémonie) : couleur unie
			n.albedo_texture = null
			n.albedo_color = couleur
		else:
			n.albedo_texture = _gris(n.albedo_texture)
			n.albedo_color = couleur * 2.2
			n.albedo_color.a = 1.0
		n.metallic = 0.0
		n.roughness = 0.85
		r = n
	_teints[cle] = r
	return r


## Gilet haute visibilité, d'après Gilet_Haute_Visibilite_SDIS37.glb : jaune fluo et deux
## bandes réfléchissantes, mais sculpté autour du buste (le modèle d'origine est un bloc
## qui ne suit pas la veste). Accroché à l'os du buste, il suit la respiration et la marche.
func _poser_gilet() -> void:
	if not _os.has("dos1"):
		return
	var att := BoneAttachment3D.new()
	att.bone_idx = _os["dos1"]
	_sk.add_child(att)
	var pivot := Node3D.new()
	att.add_child(pivot)
	var bg: Basis = (_bind[_os["dos1"]] as Transform3D).basis.orthonormalized()
	pivot.basis = bg.inverse() * Basis(Vector3.UP, PI)
	pivot.scale = Vector3.ONE / maxf(_echelle, 0.0001)
	var fluo := StandardMaterial3D.new()
	fluo.albedo_color = Color(0.86, 0.95, 0.12)
	fluo.emission_enabled = true
	fluo.emission = Color(0.25, 0.3, 0.0)
	fluo.roughness = 0.75
	var bande := StandardMaterial3D.new()
	bande.albedo_color = Color(0.82, 0.84, 0.86)
	bande.metallic = 0.6
	bande.roughness = 0.3
	var y0 := GILET_POS.y
	var lx := GILET_ECHELLE.x
	var lz := GILET_ECHELLE.z
	var dz := GILET_POS.z
	var ly := GILET_ECHELLE.y
	# Sections du gilet, de la taille aux épaules : [hauteur, demi-largeur, demi-profondeur, décalage avant]
	var corps_gilet := [[y0, 0.2 * lx, 0.15 * lz, dz], [y0 + 0.12 * ly, 0.205 * lx, 0.155 * lz, dz], [y0 + 0.3 * ly, 0.215 * lx, 0.16 * lz, dz],
		[y0 + 0.42 * ly, 0.2 * lx, 0.15 * lz, dz], [y0 + 0.47 * ly, 0.12 * lx, 0.11 * lz, dz], [y0 + 0.49 * ly, 0.07 * lx, 0.07 * lz, dz]]
	var mi := MeshInstance3D.new()
	mi.mesh = Corps.loft(corps_gilet, 16)
	mi.material_override = fluo
	pivot.add_child(mi)
	for yb in [0.07, 0.25]:
		var r := 1.04
		var anneaux := [[y0 + yb * ly, 0.203 * lx * r, 0.153 * lz * r, dz], [y0 + (yb + 0.05) * ly, 0.207 * lx * r, 0.156 * lz * r, dz]]
		var b := MeshInstance3D.new()
		b.mesh = Corps.loft(anneaux, 16)
		b.material_override = bande
		pivot.add_child(b)
	_gilet = att


## Réglage du gilet sur le buste (repère de l'os du buste, en mètres).
static var GILET_POS := Vector3(0, -0.28, 0.0)
static var GILET_ECHELLE := Vector3(1.17, 1.12, 1.3)


# ---------------------------------------------------------------------------
# Interface commune avec corps.gd
# ---------------------------------------------------------------------------

func equiper(casque: bool, ari: bool) -> void:
	_casque_on = casque or ari
	_ari_on = ari
	_montrer("casque", _casque_on)
	_montrer("masque", _ari_on)
	_montrer("ari", _ari_on)
	# Cagoule avec le casque ; visage nu en F1
	var tete_nue := not _casque_on and _tete_code != null
	_montrer("cagoule", not tete_nue)
	if _tete_code != null:
		_tete_code.visible = tete_nue


func _montrer(cle: String, v: bool) -> void:
	for mi in _pieces.get(cle, []):
		(mi as MeshInstance3D).visible = v


func allonger(_v: bool) -> void:
	pass


## Marche (ou course au-delà de 3 m/s) quand vitesse > 0, respiration au repos.
func animer(vitesse: float, delta: float) -> void:
	if _sk == null:
		return
	_t += delta
	var course: bool = vitesse > 3.0
	if vitesse > 0.05:
		_pas += delta * (vitesse * (2.6 if course else 3.6) + 1.2)
	else:
		_pas = move_toward(_pas, round(_pas / PI) * PI, delta * 5.0)
	var amp: float = clampf(vitesse / 1.4, 0.0, 1.0) * (1.25 if course else 1.0)
	var repos: float = 1.0 - clampf(amp, 0.0, 1.0)
	var s: float = sin(_pas)
	var X := Vector3.RIGHT
	var Y := Vector3.UP
	var Z := Vector3.BACK
	# Le modèle regarde vers +z : une jambe vers l'avant = rotation négative autour de x.
	var resp: float = sin(_t * 1.7) * 0.012 * repos
	_tourner("hanches", _rot(Y, -s * 0.07 * amp))
	_tourner("dos", _rot(X, (0.05 if course else 0.015) * amp + resp))
	_tourner("dos1", _rot(Y, s * 0.06 * amp))
	_tourner("dos2", _rot(Y, s * 0.04 * amp) * _rot(X, -resp))
	_tourner("tete", _rot(Y, sin(_t * 0.37) * 0.25 * repos))
	for i in 2:
		var g: bool = i == 0
		var cote: float = 1.0 if g else -1.0   # gauche du personnage = +x dans le modèle
		var phase: float = _pas + (0.0 if g else PI)
		var si: float = sin(phase)
		var ci: float = cos(phase)
		var sfx := "_g" if g else "_d"
		# Jambes (rotations relatives au segment parent) : légèrement écartées au repos
		var cuisse: float = -si * 0.5 * amp
		var genou: float = (maxf(0.0, ci) * (1.1 if not course else 1.5) + 0.12) * amp + 0.03
		_tourner("cuisse" + sfx, _rot(X, cuisse) * _rot(Z, cote * 0.03))
		_tourner("genou" + sfx, _rot(X, genou))
		_tourner("pied" + sfx, _rot(X, -(cuisse + genou) * 0.75))
		# Bras : du bras en croix au bras le long du corps, puis balancement en opposition
		var bas := _rot(Z, -cote * (_baisse + sin(_t * 1.7) * 0.01 * repos))
		_tourner("clavicule" + sfx, _rot(Z, -cote * 0.04))
		_tourner("bras" + sfx, _rot(X, si * 0.35 * amp) * bas)
		var flexion: float = 0.2 + (0.35 + maxf(0.0, -si) * 0.45) * amp + (0.8 if course else 0.0) * amp
		_tourner("avbras" + sfx, _rot(Y, -cote * flexion))
		_tourner("main" + sfx, _rot(X, 0.0))
	# Pieds à plat sur le sol, bassin qui monte et descend
	var dy: float = absf(cos(_pas)) * 0.025 * amp - 0.012 * amp - 0.03 * amp
	_modele.position.y = -_y_sol * _echelle + dy
