## Le VSAV en détail : fourgon tôlé rouge à toit surélevé, bandes jaunes, chevrons rouge et jaune
## à l'arrière, gyrophares bleus. Les portes s'ouvrent (avant, latérale coulissante, arrière
## battantes) et la cellule sanitaire est équipée : brancard rouge sur support inox, deux sièges,
## main courante bleue, tiroirs, sac d'intervention, bouteille d'oxygène, défibrillateur (DSA).
## Modèle fait à la main, sans marque ni logo. L'avant est vers -z.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")

const L := 5.9          # longueur
const W := 2.1          # largeur
const H := 2.78         # hauteur du toit
const SOL := 0.72       # plancher de la cellule
const Z_AV := -2.95     # nez
const Z_AR := 2.95      # arrière
const Z_CLOISON := -0.95  # cloison entre cabine et cellule

static var _m: Dictionary = {}


static func _mats() -> void:
	if not _m.is_empty():
		return
	_m["rouge"] = Tex.carrosserie(Color(0.75, 0.03, 0.03))
	_m["blanc"] = Tex.carrosserie(Color(0.95, 0.95, 0.94))
	_m["noir"] = Tex.carrosserie(Color(0.05, 0.05, 0.06))
	_m["gris"] = Tex.carrosserie(Color(0.35, 0.36, 0.38))
	_m["inox"] = _metal(Color(0.78, 0.79, 0.8))
	_m["jaune"] = Tex.emissif(Color(1.0, 0.85, 0.05), 0.12)
	var vt := StandardMaterial3D.new()
	vt.albedo_color = Color(0.1, 0.14, 0.18, 0.42)
	vt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vt.metallic = 0.6
	vt.roughness = 0.05
	_m["vitre"] = vt
	_m["int"] = Geo.mat(Color(0.93, 0.94, 0.95))
	_m["plancher"] = Geo.mat(Color(0.28, 0.31, 0.36))
	_m["siege"] = Geo.mat(Color(0.25, 0.27, 0.3))
	_m["siege2"] = Geo.mat(Color(0.4, 0.42, 0.45))
	_m["matelas"] = Tex.carrosserie(Color(0.85, 0.08, 0.06))
	_m["bleu"] = Geo.mat(Color(0.15, 0.4, 0.8))
	_m["sac"] = Geo.mat(Color(0.08, 0.15, 0.4))
	_m["fluo"] = Tex.emissif(Color(0.85, 1.0, 0.1), 0.2)
	_m["phare"] = Tex.emissif(Color(1, 1, 0.92), 0.8)
	_m["feu_ar"] = Tex.emissif(Color(0.85, 0.03, 0.03), 0.5)
	_m["orange"] = Tex.emissif(Color(1.0, 0.5, 0.05), 0.3)
	var ch := StandardMaterial3D.new()
	ch.albedo_texture = Tex.chevrons()
	ch.uv1_triplanar = true   # repère local : les chevrons ne glissent pas quand l'engin roule
	ch.uv1_scale = Vector3(1.6, 1.6, 1.6)
	ch.metallic = 0.2
	ch.roughness = 0.4
	_m["chevrons"] = ch
	var vb := StandardMaterial3D.new()
	vb.albedo_color = Color(0.3, 0.5, 0.75, 0.55)
	vb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_m["placard"] = vb


static func _metal(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.8
	m.roughness = 0.3
	return m


static func _b(parent: Node, taille: Vector3, pos: Vector3, nom_mat: String, solide: bool = false) -> Node3D:
	return Geo.boite_mat(parent, taille, pos, _m[nom_mat], solide)


static func _cyl(parent: Node, r: float, h: float, pos: Vector3, nom_mat: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 16
	mi.mesh = cm
	mi.material_override = _m[nom_mat]
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _texte(parent: Node, t: String, pos: Vector3, rot_y: float, taille: int, pixel: float, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font_size = taille
	l.pixel_size = pixel
	l.modulate = c
	l.outline_size = 0
	l.double_sided = false
	l.position = pos
	l.rotation.y = rot_y
	parent.add_child(l)
	return l


## Construit le VSAV dans l'engin "e" et renvoie la description des portes.
static func construire(e: Node3D) -> Dictionary:
	_mats()
	_chassis(e)
	_cabine(e)
	_caisse(e)
	_arriere(e)
	_feux_et_gyros(e)
	_inscriptions(e)
	_cellule(e)
	return _portes(e)


static func _chassis(e: Node3D) -> void:
	# Soubassement et plancher (on peut marcher dans la cellule)
	_b(e, Vector3(W - 0.2, 0.3, L - 0.4), Vector3(0, 0.45, 0.1), "noir", true)
	_b(e, Vector3(W - 0.06, 0.1, Z_AR - Z_CLOISON), Vector3(0, SOL - 0.05, (Z_AR + Z_CLOISON) * 0.5), "plancher", true)
	# Roues : pneus et enjoliveurs argent
	for zz in [-1.95, 1.75]:
		for xx in [-W * 0.5 + 0.15, W * 0.5 - 0.15]:
			_cyl(e, 0.37, 0.24, Vector3(xx, 0.37, zz), "noir", Vector3(0, 0, PI * 0.5))
			_cyl(e, 0.24, 0.26, Vector3(xx, 0.37, zz), "inox", Vector3(0, 0, PI * 0.5))
			_cyl(e, 0.08, 0.28, Vector3(xx, 0.37, zz), "gris", Vector3(0, 0, PI * 0.5))
			# Passage de roue noir
			_b(e, Vector3(0.06, 0.25, 0.95), Vector3(signf(xx) * (W * 0.5 + 0.025), 0.78, zz), "noir")


static func _cabine(e: Node3D) -> void:
	# Capot plongeant, calandre noire, pare-chocs blanc
	_b(e, Vector3(W - 0.04, 0.55, 0.95), Vector3(0, 1.0, -2.47), "rouge", true)
	var capot := _b(e, Vector3(W - 0.08, 0.06, 0.95), Vector3(0, 1.29, -2.45), "rouge")
	capot.rotation.x = 0.12
	_b(e, Vector3(W, 0.42, 0.25), Vector3(0, 0.52, Z_AV + 0.1), "blanc")
	_b(e, Vector3(1.2, 0.08, 0.05), Vector3(0, 0.42, Z_AV - 0.02), "noir")
	_b(e, Vector3(1.25, 0.38, 0.05), Vector3(0, 0.95, Z_AV - 0.01), "noir")
	for k in 5:
		_b(e, Vector3(1.2, 0.025, 0.02), Vector3(0, 0.82 + k * 0.065, Z_AV - 0.04), "gris")
	# Bandeau de chevrons au-dessus de la calandre
	_b(e, Vector3(W - 0.1, 0.16, 0.04), Vector3(0, 1.22, Z_AV + 0.02), "chevrons")
	# Plaque d'immatriculation (sans numéro)
	_b(e, Vector3(0.52, 0.11, 0.02), Vector3(0, 0.55, Z_AV - 0.04), "blanc")
	# Phares en amande
	for cote in [-1.0, 1.0]:
		var ph := _b(e, Vector3(0.42, 0.17, 0.05), Vector3(cote * 0.78, 1.08, Z_AV + 0.0), "phare")
		ph.rotation.z = -cote * 0.18
		_b(e, Vector3(0.12, 0.06, 0.04), Vector3(cote * 0.9, 0.62, Z_AV - 0.02), "orange")
	# Pare-brise incliné et montants
	var pb := _b(e, Vector3(W - 0.16, 1.3, 0.04), Vector3(0, 1.88, -1.67), "vitre")
	pb.rotation.x = 0.52
	for cote in [-1.0, 1.0]:
		var montant := _b(e, Vector3(0.1, 1.32, 0.08), Vector3(cote * (W * 0.5 - 0.05), 1.88, -1.67), "rouge")
		montant.rotation.x = 0.52
	# Toit de cabine qui remonte vers le toit surélevé
	_b(e, Vector3(W, 0.08, 0.5), Vector3(0, 2.45, -1.15), "rouge")
	var deflecteur := _b(e, Vector3(W, 0.06, 0.55), Vector3(0, 2.63, -1.25), "rouge")
	deflecteur.rotation.x = -0.6
	# Bas de caisse sous les portes avant
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.05, 0.25, 1.0), Vector3(cote * (W * 0.5 - 0.02), 0.62, -1.5), "noir")
		# Marchepied
		_b(e, Vector3(0.25, 0.05, 0.7), Vector3(cote * (W * 0.5 - 0.1), 0.42, -1.5), "noir")
	# Intérieur de la cabine : planche de bord, volant, sièges
	_b(e, Vector3(W - 0.15, 0.4, 0.45), Vector3(0, 1.3, -2.05), "noir", true)
	_b(e, Vector3(W - 0.15, 0.06, 0.3), Vector3(0, 1.52, -1.95), "gris")
	_cyl(e, 0.2, 0.04, Vector3(-0.5, 1.55, -1.72), "noir", Vector3(1.1, 0, 0))
	_b(e, Vector3(0.3, 0.16, 0.04), Vector3(0.1, 1.6, -1.9), "noir")
	for xs in [-0.5, 0.25, 0.65]:
		_b(e, Vector3(0.42 if xs < 0.0 else 0.38, 0.12, 0.45), Vector3(xs, 1.08, -1.2), "siege")
		_b(e, Vector3(0.42 if xs < 0.0 else 0.38, 0.65, 0.1), Vector3(xs, 1.45, -1.02), "siege")
		_b(e, Vector3(0.24, 0.18, 0.08), Vector3(xs, 1.9, -1.02), "siege2")
	_b(e, Vector3(W - 0.08, 0.1, 1.05), Vector3(0, 0.67, -1.5), "noir", true)


static func _caisse(e: Node3D) -> void:
	var lz: float = Z_AR - Z_CLOISON
	var cz: float = (Z_AR + Z_CLOISON) * 0.5
	var hc: float = H - SOL
	var yc: float = SOL + hc * 0.5
	# Côté gauche, sans fenêtre : tôle rouge à l'extérieur, paroi blanche à l'intérieur
	_b(e, Vector3(0.04, hc + 0.3, lz), Vector3(-W * 0.5 + 0.02, yc - 0.15, cz), "rouge", true)
	_b(e, Vector3(0.03, hc, lz), Vector3(-W * 0.5 + 0.06, yc, cz), "int")
	# Côté droit : montant avant, porte coulissante (à part), panneau arrière
	var z0 := 0.55
	_b(e, Vector3(0.04, hc + 0.3, Z_AR - z0), Vector3(W * 0.5 - 0.02, yc - 0.15, (Z_AR + z0) * 0.5), "rouge", true)
	_b(e, Vector3(0.03, hc, Z_AR - z0), Vector3(W * 0.5 - 0.06, yc, (Z_AR + z0) * 0.5), "int")
	_b(e, Vector3(0.04, hc + 0.3, 0.2), Vector3(W * 0.5 - 0.02, yc - 0.15, Z_CLOISON + 0.1), "rouge", true)
	# Rail de la porte coulissante
	_b(e, Vector3(0.05, 0.05, Z_AR - z0 - 0.2), Vector3(W * 0.5 + 0.01, 1.35, (Z_AR + z0) * 0.5 - 0.1), "noir")
	# Seuil de porte latérale
	_b(e, Vector3(0.25, 0.04, 1.3), Vector3(W * 0.5 - 0.15, SOL + 0.01, -0.1), "inox")
	# Toit
	_b(e, Vector3(W, 0.08, Z_AR - (-1.45)), Vector3(0, H, (Z_AR - 1.45) * 0.5), "rouge")
	_b(e, Vector3(W - 0.1, 0.03, lz), Vector3(0, H - 0.06, cz), "int")
	# Cloison cabine / cellule avec vitre de communication
	_b(e, Vector3(W - 0.1, hc, 0.06), Vector3(0, yc, Z_CLOISON), "int", true)
	_b(e, Vector3(0.8, 0.35, 0.02), Vector3(-0.1, 2.15, Z_CLOISON + 0.04), "vitre")
	_b(e, Vector3(0.8, 0.35, 0.02), Vector3(-0.1, 2.15, Z_CLOISON - 0.04), "vitre")
	# Bas de caisse noir des deux côtés
	_b(e, Vector3(0.05, 0.22, lz - 0.6), Vector3(-W * 0.5 - 0.025, 0.85, cz - 0.3), "noir")
	_b(e, Vector3(0.05, 0.22, Z_AR - z0 - 0.3), Vector3(W * 0.5 + 0.025, 0.85, (Z_AR + z0) * 0.5 - 0.15), "noir")
	# Grilles d'aération à gauche
	for k in 2:
		_b(e, Vector3(0.03, 0.18, 0.3), Vector3(-W * 0.5 - 0.03, 1.2, -0.4 + k * 0.6), "noir")
	# Bandes jaunes : ligne de ceinture, contour du haut et verticale arrière
	for cote in [-1.0, 1.0]:
		var xs: float = cote * (W * 0.5 + 0.012)
		if cote < 0.0:
			_b(e, Vector3(0.01, 0.06, lz), Vector3(xs, 1.12, cz), "jaune")
		else:
			_b(e, Vector3(0.01, 0.06, Z_AR - z0), Vector3(xs, 1.12, (Z_AR + z0) * 0.5), "jaune")
		_b(e, Vector3(0.01, 0.06, Z_AR + 1.0), Vector3(xs, 2.62, (Z_AR - 1.0) * 0.5), "jaune")
		_b(e, Vector3(0.01, 1.5, 0.06), Vector3(xs, 1.87, Z_AR - 0.3), "jaune")
		_b(e, Vector3(0.01, 0.06, 1.05), Vector3(xs, 1.12, -2.45), "jaune")


static func _arriere(e: Node3D) -> void:
	# Montants arrière, traverse haute, feux verticaux sur les montants
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.08, H - 0.45, 0.06), Vector3(cote * (W * 0.5 - 0.04), (H + 0.45) * 0.5, Z_AR - 0.03), "rouge", true)
		_b(e, Vector3(0.1, 0.85, 0.07), Vector3(cote * (W * 0.5 - 0.06), 1.15, Z_AR - 0.0), "feu_ar")
		_b(e, Vector3(0.1, 0.12, 0.07), Vector3(cote * (W * 0.5 - 0.06), 1.65, Z_AR - 0.0), "orange")
	_b(e, Vector3(W, 0.2, 0.06), Vector3(0, H - 0.1, Z_AR - 0.03), "rouge")
	# Pare-chocs arrière : coins blancs et marchepied noir
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.35, 0.4, 0.3), Vector3(cote * (W * 0.5 - 0.17), 0.5, Z_AR + 0.05), "blanc")
	_b(e, Vector3(W - 0.7, 0.08, 0.45), Vector3(0, 0.42, Z_AR + 0.2), "noir", true)
	for k in 6:
		_b(e, Vector3(0.02, 0.09, 0.42), Vector3(-0.6 + k * 0.24, 0.43, Z_AR + 0.2), "gris")


static func _feux_et_gyros(e: Node3D) -> void:
	# Rampe bleue sur le toit à l'avant, feux bleus aux coins arrière, feux de pénétration
	_b(e, Vector3(1.5, 0.1, 0.3), Vector3(0, H + 0.08, -1.25), "noir")
	var places: Array = [Vector3(-0.55, H + 0.2, -1.25), Vector3(0.55, H + 0.2, -1.25), Vector3(-W * 0.5 + 0.15, H + 0.12, Z_AR - 0.15), Vector3(W * 0.5 - 0.15, H + 0.12, Z_AR - 0.15), Vector3(-0.35, 1.05, Z_AV - 0.03), Vector3(0.35, 1.05, Z_AV - 0.03)]
	for i in places.size():
		var m: StandardMaterial3D = Tex.emissif(Color(0.15, 0.3, 1.0), 0.0)
		e._mats_gyro.append(m)
		var taille := Vector3(0.45, 0.16, 0.25) if i < 2 else (Vector3(0.18, 0.14, 0.18) if i < 4 else Vector3(0.14, 0.06, 0.03))
		var g: Node3D = Geo.boite_mat(e, taille, places[i], m, false)
		if i < 2:
			var lum := OmniLight3D.new()
			lum.light_color = Color(0.2, 0.35, 1.0)
			lum.omni_range = 10.0
			lum.light_energy = 0.0
			g.add_child(lum)
			e._gyros.append(lum)
	# Rétroviseurs de fourgon (grands, noirs) sur bras
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.3, 0.04, 0.04), Vector3(cote * (W * 0.5 + 0.12), 1.75, -1.95), "noir")
		_b(e, Vector3(0.07, 0.42, 0.24), Vector3(cote * (W * 0.5 + 0.27), 1.68, -1.95), "noir")


static func _inscriptions(e: Node3D) -> void:
	var jaune := Color(1.0, 0.85, 0.1)
	# Côté gauche : panneau fixe. Côté droit : panneau derrière la porte coulissante.
	var gauche := -W * 0.5 - 0.03
	var rg := -PI * 0.5
	_texte(e, "SAPEURS-POMPIERS DE TOURAINE", Vector3(gauche, 2.42, 1.0), rg, 48, 0.004, jaune)
	_texte(e, "VÉHICULE DE SECOURS ET", Vector3(gauche, 1.55, 1.0), rg, 44, 0.0042, jaune)
	_texte(e, "D'ASSISTANCE AUX VICTIMES", Vector3(gauche, 1.36, 1.0), rg, 44, 0.0042, jaune)
	var droite := W * 0.5 + 0.03
	var rd := PI * 0.5
	_texte(e, "SAPEURS-POMPIERS", Vector3(droite, 2.42, 1.75), rd, 48, 0.004, jaune)
	_texte(e, "DE TOURAINE", Vector3(droite, 2.24, 1.75), rd, 40, 0.004, jaune)
	_texte(e, "VÉHICULE DE SECOURS ET", Vector3(droite, 1.55, 1.75), rd, 40, 0.0038, jaune)
	_texte(e, "D'ASSISTANCE AUX VICTIMES", Vector3(droite, 1.36, 1.75), rd, 40, 0.0038, jaune)
	# Cartouche 18 / 112
	for cote in [-1.0, 1.0]:
		var x: float = cote * (W * 0.5 + 0.02)
		var z: float = 2.45 if cote > 0.0 else 2.3
		_b(e, Vector3(0.01, 0.5, 0.45), Vector3(x, 1.95, z), "jaune")
		_b(e, Vector3(0.012, 0.44, 0.39), Vector3(x + cote * 0.002, 1.95, z), "rouge")
		_texte(e, "18", Vector3(x + cote * 0.01, 2.05, z), cote * PI * 0.5, 60, 0.0035, jaune)
		_texte(e, "112", Vector3(x + cote * 0.01, 1.84, z), cote * PI * 0.5, 60, 0.0035, jaune)
	# Code de l'engin à l'avant, en haut du pare-brise
	var av := _texte(e, "VSAV 1 · JOUÉ-LÈS-TOURS", Vector3(0, 2.52, -1.43), PI, 40, 0.004, Color(1, 1, 1))
	av.rotation.x = 0.6


static func _cellule(e: Node3D) -> void:
	var f := SOL
	# Éclairage de plafond
	for z in [0.0, 1.6]:
		_b(e, Vector3(0.6, 0.03, 0.5), Vector3(0, H - 0.09, z), "phare")
	var lum := OmniLight3D.new()
	lum.position = Vector3(0, H - 0.3, 1.0)
	lum.omni_range = 3.5
	lum.light_energy = 0.7
	lum.light_color = Color(1.0, 0.97, 0.92)
	e.add_child(lum)
	# --- Brancard rouge sur support inox (côté gauche, tête vers l'avant)
	var bx := -0.38
	_b(e, Vector3(0.68, 0.32, 2.05), Vector3(bx, f + 0.16, 1.45), "inox")
	_b(e, Vector3(0.7, 0.02, 2.05), Vector3(bx, f + 0.33, 1.45), "gris")
	_b(e, Vector3(0.3, 0.12, 0.05), Vector3(bx, f + 0.2, 2.48), "matelas")
	for zz in [0.6, 2.3]:
		for xx in [-0.25, 0.25]:
			_b(e, Vector3(0.04, 0.4, 0.04), Vector3(bx + xx, f + 0.52, zz), "inox")
	_b(e, Vector3(0.6, 0.06, 1.9), Vector3(bx, f + 0.72, 1.5), "inox")
	_b(e, Vector3(0.56, 0.12, 1.25), Vector3(bx, f + 0.8, 1.85), "matelas")
	var dossier := _b(e, Vector3(0.56, 0.12, 0.7), Vector3(bx, f + 0.98, 0.92), "matelas")
	dossier.rotation.x = 0.55
	# Cadre blanc relevé à la tête (comme sur la photo) et barrières latérales
	var cadre := Node3D.new()
	cadre.position = Vector3(bx, f + 0.78, 0.72)
	cadre.rotation.x = 0.5
	e.add_child(cadre)
	for xx in [-0.3, 0.3]:
		_b(cadre, Vector3(0.04, 0.75, 0.04), Vector3(xx, 0.37, 0), "blanc")
	_b(cadre, Vector3(0.64, 0.05, 0.25), Vector3(0, 0.76, 0.05), "blanc")
	for xx in [-0.31, 0.31]:
		_b(e, Vector3(0.03, 0.03, 1.2), Vector3(bx + xx, f + 0.95, 1.85), "inox")
	# Sangles noires
	for zz in [1.35, 1.9, 2.3]:
		_b(e, Vector3(0.58, 0.02, 0.06), Vector3(bx, f + 0.865, zz), "noir")
	# Victime allongée, cachée tant qu'elle n'est pas chargée
	var pat := Node3D.new()
	pat.name = "PatientABord"
	pat.visible = false
	e.add_child(pat)
	_b(pat, Vector3(0.4, 0.22, 0.7), Vector3(bx, f + 1.0, 1.35), "siege2")
	_b(pat, Vector3(0.36, 0.18, 0.85), Vector3(bx, f + 0.95, 2.05), "sac")
	_b(pat, Vector3(0.5, 0.05, 1.3), Vector3(bx, f + 1.06, 1.85), "inox")
	var tete := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	tete.mesh = sm
	tete.material_override = Geo.mat(Color(0.92, 0.76, 0.64))
	tete.position = Vector3(bx, f + 1.2, 0.95)
	pat.add_child(tete)
	# --- Banquette à droite avec deux sièges gris, face au brancard
	_b(e, Vector3(0.45, 0.42, 1.7), Vector3(0.8, f + 0.21, 1.9), "int")
	_b(e, Vector3(0.02, 0.38, 1.66), Vector3(0.565, f + 0.2, 1.9), "inox")
	for zz in [1.45, 2.3]:
		_b(e, Vector3(0.42, 0.1, 0.46), Vector3(0.75, f + 0.62, zz), "siege")
		_b(e, Vector3(0.1, 0.8, 0.46), Vector3(0.95, f + 1.1, zz), "siege")
		_b(e, Vector3(0.09, 0.22, 0.3), Vector3(0.95, f + 1.62, zz), "siege")
		for dz in [-0.24, 0.24]:
			_b(e, Vector3(0.3, 0.05, 0.05), Vector3(0.78, f + 0.85, zz + dz), "siege2")
		_b(e, Vector3(0.06, 0.06, 0.06), Vector3(0.62, f + 0.47, zz + 0.2), "matelas")
	# --- Main courante bleue : verticale à la porte arrière, horizontale au plafond
	_cyl(e, 0.022, 1.6, Vector3(0.9, f + 1.05, Z_AR - 0.12), "bleu")
	for yy in [f + 0.3, f + 1.8]:
		_b(e, Vector3(0.1, 0.03, 0.03), Vector3(0.95, yy, Z_AR - 0.12), "bleu")
	_cyl(e, 0.02, 3.4, Vector3(0.25, H - 0.2, 1.0), "bleu", Vector3(PI * 0.5, 0, 0))
	# --- Cloison avant : armoire, tiroirs à serrures rondes, plan de travail, DSA
	var zc := Z_CLOISON + 0.25
	_b(e, Vector3(0.45, 1.75, 0.4), Vector3(-0.73, f + 0.875, zc - 0.03), "int")
	for yy in [0.45, 1.05, 1.5]:
		_b(e, Vector3(0.41, 0.01, 0.01), Vector3(-0.73, f + yy, zc + 0.175), "siege2")
		_cyl(e, 0.03, 0.02, Vector3(-0.73, f + yy + 0.2, zc + 0.18), "inox", Vector3(PI * 0.5, 0, 0))
	_b(e, Vector3(0.7, 0.95, 0.4), Vector3(-0.08, f + 0.48, zc - 0.03), "int")
	for k in 4:
		_b(e, Vector3(0.32, 0.01, 0.01), Vector3(-0.08, f + 0.22 + k * 0.23, zc + 0.175), "siege2")
		_cyl(e, 0.025, 0.02, Vector3(-0.08, f + 0.33 + k * 0.23, zc + 0.18), "inox", Vector3(PI * 0.5, 0, 0))
	_b(e, Vector3(1.5, 0.04, 0.5), Vector3(0.1, f + 1.02, zc), "int")
	_b(e, Vector3(1.5, 0.04, 0.35), Vector3(0.1, f + 1.65, zc - 0.07), "int")
	# Défibrillateur (DSA) : boîtier bleu, poignée jaune
	_b(e, Vector3(0.32, 0.38, 0.1), Vector3(0.55, f + 1.42, Z_CLOISON + 0.09), "bleu")
	_b(e, Vector3(0.12, 0.08, 0.04), Vector3(0.55, f + 1.64, Z_CLOISON + 0.11), "fluo")
	_texte(e, "DSA", Vector3(0.55, f + 1.38, Z_CLOISON + 0.145), 0.0, 40, 0.003, Color(1, 1, 1))
	# Moniteur au-dessus du plan de travail
	_b(e, Vector3(0.45, 0.3, 0.05), Vector3(-0.1, f + 1.25, Z_CLOISON + 0.12), "noir")
	_b(e, Vector3(0.4, 0.24, 0.01), Vector3(-0.1, f + 1.25, Z_CLOISON + 0.15), "vitre")
	# Sac d'intervention bleu à bandes jaunes, au sol contre les tiroirs
	_b(e, Vector3(0.5, 0.48, 0.32), Vector3(0.55, f + 0.24, zc + 0.05), "sac")
	for yy in [0.12, 0.4]:
		_b(e, Vector3(0.51, 0.05, 0.33), Vector3(0.55, f + yy, zc + 0.05), "fluo")
	_b(e, Vector3(0.3, 0.06, 0.06), Vector3(0.55, f + 0.52, zc + 0.05), "noir")
	# Matelas immobilisateur roulé (rouge) et attelles
	_b(e, Vector3(0.18, 0.75, 0.25), Vector3(0.9, f + 0.42, Z_CLOISON + 0.2), "matelas")
	for yy in [0.2, 0.6]:
		_b(e, Vector3(0.19, 0.04, 0.26), Vector3(0.9, f + yy, Z_CLOISON + 0.2), "fluo")
	# --- Paroi gauche : sac orange et bleu sanglé, bouteille d'oxygène, placards hauts
	_b(e, Vector3(0.22, 0.95, 0.55), Vector3(-0.89, f + 1.05, 2.0), "bleu")
	_b(e, Vector3(0.23, 0.35, 0.56), Vector3(-0.89, f + 1.38, 2.0), "orange")
	for yy in [0.75, 1.15]:
		_b(e, Vector3(0.24, 0.04, 0.6), Vector3(-0.89, f + yy, 2.0), "noir")
	for zz in [1.4, 1.6]:
		_b(e, Vector3(0.14, 0.03, 0.03), Vector3(-0.93, f + 1.25, zz), "inox")
	_cyl(e, 0.1, 0.8, Vector3(-0.85, f + 0.42, 2.68), "blanc")
	_cyl(e, 0.045, 0.12, Vector3(-0.85, f + 0.88, 2.68), "inox")
	_b(e, Vector3(0.12, 0.08, 0.1), Vector3(-0.85, f + 0.97, 2.68), "siege2")
	_b(e, Vector3(0.25, 0.05, 0.05), Vector3(-0.9, f + 0.6, 2.68), "noir")
	_b(e, Vector3(0.35, 0.35, 3.2), Vector3(-0.85, H - 0.32, 1.0), "placard")
	_b(e, Vector3(0.36, 0.02, 3.2), Vector3(-0.85, H - 0.5, 1.0), "int")
	# Tapis antidérapant jaune devant les tiroirs
	_b(e, Vector3(0.5, 0.01, 0.35), Vector3(0.25, f + 0.005, Z_CLOISON + 0.7), "fluo")


## Les portes : chaque porte est un pivot animé par l'engin.
static func _portes(e: Node3D) -> Dictionary:
	var portes := {}
	# Portes arrière battantes (vitrées en haut, chevrons à l'extérieur, rouges à l'intérieur)
	for cote in [-1.0, 1.0]:
		var p := Node3D.new()
		p.position = Vector3(cote * (W * 0.5 - 0.02), 0, Z_AR + 0.01)
		e.add_child(p)
		var cx: float = -cote * 0.5
		var hp: float = H - 0.2 - (SOL - 0.08)
		var yp: float = (SOL - 0.08) + hp * 0.5
		_b(p, Vector3(1.0, hp, 0.05), Vector3(cx, yp, 0), "rouge", true)
		_b(p, Vector3(0.98, hp - 0.02, 0.01), Vector3(cx, yp, 0.03), "chevrons")
		_b(p, Vector3(0.68, 0.55, 0.012), Vector3(cx + cote * 0.05, 2.15, 0.04), "vitre")
		_b(p, Vector3(0.6, 0.05, 0.03), Vector3(cx, 1.05, -0.04), "noir")
		if cote > 0.0:
			_b(p, Vector3(0.18, 0.05, 0.04), Vector3(-0.8, 1.35, 0.05), "noir")
		var nom := "arriere_gauche" if cote < 0.0 else "arriere_droite"
		portes[nom] = {"noeud": p, "type": "pivot", "ferme": 0.0, "ouvre": (-1.0 if cote < 0.0 else 1.0) * deg_to_rad(165.0), "t": 0.0, "ouvert": false,
			"point": Vector3(cote * 0.55, 1.2, Z_AR + 0.35), "texte": "la porte arrière " + ("gauche" if cote < 0.0 else "droite")}
	# Porte latérale coulissante (côté droit)
	var pl := Node3D.new()
	pl.position = Vector3(W * 0.5 + 0.0, 0, -0.1)
	e.add_child(pl)
	_b(pl, Vector3(0.05, H - 0.3 - (SOL - 0.2), 1.3), Vector3(0, (SOL - 0.2 + H - 0.3) * 0.5, 0), "rouge", true)
	_b(pl, Vector3(0.012, 0.55, 0.85), Vector3(0.03, 2.05, -0.1), "vitre")
	_b(pl, Vector3(0.01, 0.06, 1.3), Vector3(0.03, 1.12, 0), "jaune")
	_b(pl, Vector3(0.01, 0.06, 1.3), Vector3(0.03, 2.62, 0), "jaune")
	_b(pl, Vector3(0.05, 0.22, 1.3), Vector3(0.03, 0.85, 0), "noir")
	_b(pl, Vector3(0.04, 0.05, 0.2), Vector3(0.05, 1.35, -0.45), "noir")
	_b(pl, Vector3(0.02, H - 0.3 - SOL, 1.26), Vector3(-0.035, (SOL + H - 0.3) * 0.5, 0), "int")
	portes["laterale"] = {"noeud": pl, "type": "glisse", "ferme": pl.position, "ouvre": pl.position + Vector3(0.12, 0, 1.38), "t": 0.0, "ouvert": false,
		"point": Vector3(W * 0.5 + 0.4, 1.2, -0.3), "texte": "la porte latérale"}
	# Portes avant de la cabine (charnière à l'avant), vitre et rétroviseur
	for cote in [-1.0, 1.0]:
		var pa := Node3D.new()
		pa.position = Vector3(cote * (W * 0.5 - 0.01), 0, -2.0)
		e.add_child(pa)
		_b(pa, Vector3(0.05, 0.95, 1.0), Vector3(0, 0.98, 0.5), "rouge", true)
		_b(pa, Vector3(0.05, 0.85, 0.12), Vector3(0, 1.88, 0.94), "rouge")
		_b(pa, Vector3(0.03, 0.8, 0.85), Vector3(0, 1.86, 0.43), "vitre")
		_b(pa, Vector3(0.05, 0.06, 1.0), Vector3(0, 2.3, 0.5), "rouge")
		_b(pa, Vector3(0.01, 0.06, 1.0), Vector3(cote * 0.03, 1.12, 0.5), "jaune")
		_b(pa, Vector3(0.04, 0.04, 0.18), Vector3(cote * 0.04, 1.3, 0.8), "noir")
		_b(pa, Vector3(0.02, 0.85, 0.95), Vector3(-cote * 0.035, 0.98, 0.5), "gris")
		var nom2 := "avant_gauche" if cote < 0.0 else "avant_droite"
		portes[nom2] = {"noeud": pa, "type": "pivot", "ferme": 0.0, "ouvre": cote * deg_to_rad(70.0), "t": 0.0, "ouvert": false,
			"point": Vector3(cote * (W * 0.5 + 0.35), 1.2, -1.5), "texte": "la porte " + ("conducteur" if cote < 0.0 else "passager")}
	return portes
