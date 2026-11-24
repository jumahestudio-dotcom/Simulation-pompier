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


func construire(p_tenue: Dictionary) -> void:
	tenue = p_tenue
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
	_pieces = {"casque": _maillages(P_CASQUE), "cagoule": _maillages(P_CAGOULE), "masque": _maillages(P_MASQUE), "ari": _maillages(P_ARI)}
	for mi in _sk.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_preparer_os()
	_poser_casque_f1()
	_preparer_tete()
	var taille: float = float(tenue.get("taille", 1.0)) * float(tenue.get("corpulence", 1.0)) * 0.5 + 0.5
	scale = Vector3.ONE * clampf(taille, 0.96, 1.05)
	equiper(false, false)
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


func _preparer_os() -> void:
	for i in _sk.get_bone_count():
		var n := _sk.get_bone_name(i)
		for cle in OS_UTILES:
			if n.begins_with("mixamorig_" + OS_UTILES[cle] + "_"):
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
		var bas := _rot(Z, -cote * (BAISSE_BRAS + sin(_t * 1.7) * 0.01 * repos))
		_tourner("clavicule" + sfx, _rot(Z, -cote * 0.04))
		_tourner("bras" + sfx, _rot(X, si * 0.35 * amp) * bas)
		var flexion: float = 0.2 + (0.35 + maxf(0.0, -si) * 0.45) * amp + (0.8 if course else 0.0) * amp
		_tourner("avbras" + sfx, _rot(Y, -cote * flexion))
		_tourner("main" + sfx, _rot(X, 0.0))
	# Pieds à plat sur le sol, bassin qui monte et descend
	var dy: float = absf(cos(_pas)) * 0.025 * amp - 0.012 * amp - 0.03 * amp
	_modele.position.y = -_y_sol * _echelle + dy
