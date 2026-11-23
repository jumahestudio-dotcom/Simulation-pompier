## Le FPT (fourgon pompe-tonne) en détail : porteur 4x2 rouge à cabine double, face avant à
## chevrons rouge et jaune, pare-chocs blanc, deux gyrophares bleus, échelle sur le toit.
## Caisse à coffres fermés par des rideaux en aluminium qui s'ouvrent sur le matériel
## (ARI, tuyaux roulés, lances, outillage), dévidoirs et échelle à crochets à l'arrière.
## Portes de cabine ouvrables. Modèle fait à la main, sans marque ni logo. L'avant est vers -z.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")

const L := 8.0
const W := 2.5
const H := 3.15          # toit de la caisse
const Z_AV := -4.0       # face avant de la cabine
const Z_CAB := -1.0      # arrière de la cabine
const Z_C0 := -0.9       # début de la caisse
const Z_C1 := 3.75       # arrière de la caisse
const SOL_CAB := 1.2     # plancher de la cabine
const Y_COF0 := 1.42     # bas des coffres hauts
const Y_COF1 := 2.9      # haut des coffres hauts
## Les trois coffres de chaque côté : [début, fin] en z
const COFFRES: Array = [[-0.82, 0.62], [0.74, 2.18], [2.3, 3.66]]

static var _m: Dictionary = {}


static func _mats() -> void:
	if not _m.is_empty():
		return
	_m["rouge"] = Tex.carrosserie(Color(0.74, 0.03, 0.03))
	_m["blanc"] = Tex.carrosserie(Color(0.95, 0.95, 0.94))
	_m["noir"] = Tex.carrosserie(Color(0.05, 0.05, 0.06))
	_m["gris"] = Tex.carrosserie(Color(0.33, 0.34, 0.36))
	_m["alu"] = _metal(Color(0.8, 0.81, 0.82), 0.35)
	_m["inox"] = _metal(Color(0.72, 0.73, 0.75), 0.25)
	_m["jaune"] = Tex.emissif(Color(1.0, 0.82, 0.05), 0.12)
	var vt := StandardMaterial3D.new()
	vt.albedo_color = Color(0.08, 0.11, 0.14, 0.45)
	vt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vt.metallic = 0.6
	vt.roughness = 0.05
	_m["vitre"] = vt
	var vf := StandardMaterial3D.new()
	vf.albedo_color = Color(0.03, 0.04, 0.05, 0.8)
	vf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vf.metallic = 0.6
	vf.roughness = 0.05
	_m["vitre_fumee"] = vf
	_m["interieur"] = Geo.mat(Color(0.2, 0.21, 0.23))
	_m["coffre"] = Geo.mat(Color(0.55, 0.57, 0.6))
	_m["siege"] = Geo.mat(Color(0.12, 0.13, 0.15))
	_m["tuyau"] = Geo.mat(Color(0.9, 0.88, 0.8))
	_m["tuyau_rouge"] = Geo.mat(Color(0.75, 0.12, 0.1))
	_m["bouteille"] = Tex.carrosserie(Color(0.95, 0.75, 0.1))
	_m["lance"] = _metal(Color(0.85, 0.15, 0.1), 0.35)
	_m["orange"] = Tex.emissif(Color(1.0, 0.45, 0.05), 0.15)
	_m["phare"] = Tex.emissif(Color(1, 1, 0.92), 0.8)
	_m["feu_ar"] = Tex.emissif(Color(0.85, 0.03, 0.03), 0.5)
	_m["clignotant"] = Tex.emissif(Color(1.0, 0.5, 0.05), 0.3)
	_m["eclairage"] = Tex.emissif(Color(1.0, 0.97, 0.9), 1.0)
	var ch := StandardMaterial3D.new()
	ch.albedo_texture = Tex.chevrons()
	ch.uv1_triplanar = true   # repère local : les chevrons ne glissent pas quand l'engin roule
	ch.uv1_scale = Vector3(1.4, 1.4, 1.4)
	ch.metallic = 0.2
	ch.roughness = 0.4
	_m["chevrons"] = ch
	var rd := StandardMaterial3D.new()
	rd.albedo_texture = _tex_rideau()
	rd.uv1_triplanar = true
	rd.uv1_scale = Vector3(2.0, 2.0, 2.0)
	rd.metallic = 0.7
	rd.roughness = 0.35
	_m["rideau"] = rd


static func _metal(c: Color, rugosite: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.85
	m.roughness = rugosite
	return m


## Rideau en aluminium : lames horizontales (environ 4 cm).
static func _tex_rideau() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var v: float = 0.86 - 0.18 * absf(sin(float(y) / 64.0 * PI * 12.0))
		if y % 16 == 0:
			v = 0.5
		for x in 64:
			img.set_pixel(x, y, Color(v, v, v * 1.01))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _b(parent: Node, taille: Vector3, pos: Vector3, nom_mat: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = taille
	mi.mesh = bm
	mi.material_override = _m[nom_mat]
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _cyl(parent: Node, r: float, h: float, pos: Vector3, nom_mat: String, rot: Vector3 = Vector3.ZERO, segments: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = segments
	cm.rings = 1
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


## Construit le FPT dans l'engin "e" et renvoie la description des portes et des rideaux.
static func construire(e: Node3D) -> Dictionary:
	_mats()
	_collision(e)
	_chassis(e)
	_cabine(e)
	_interieur_cabine(e)
	_caisse(e)
	_coffres(e)
	_arriere(e)
	_toit(e)
	_feux_et_gyros(e)
	_inscriptions(e)
	var portes := _portes(e)
	portes.merge(_rideaux(e))
	return portes


static func _collision(e: Node3D) -> void:
	# Un seul volume pour tout l'engin : on ne le traverse pas, on ne marche pas dessus.
	var corps := StaticBody3D.new()
	e.add_child(corps)
	var cs := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(W, 2.9, L + 0.3)
	cs.shape = forme
	cs.position = Vector3(0, 1.85, 0.1)
	corps.add_child(cs)


static func _chassis(e: Node3D) -> void:
	# Longerons noirs, réservoir, coffre à batteries
	for xx in [-0.45, 0.45]:
		_b(e, Vector3(0.18, 0.3, L - 0.6), Vector3(xx, 0.8, 0.0), "noir")
	_b(e, Vector3(0.5, 0.45, 0.9), Vector3(-W * 0.5 + 0.45, 0.72, -0.4), "gris")
	_b(e, Vector3(0.45, 0.4, 0.6), Vector3(W * 0.5 - 0.42, 0.72, -0.45), "noir")
	# Roues : avant simples, arrière jumelées (jantes alu)
	for zz in [-2.55, 2.0]:
		var jumelee: bool = zz > 0.0
		for cote in [-1.0, 1.0]:
			var xx: float = cote * (W * 0.5 - (0.3 if jumelee else 0.22))
			var larg: float = 0.62 if jumelee else 0.4
			_cyl(e, 0.55, larg, Vector3(xx, 0.55, zz), "noir", Vector3(0, 0, PI * 0.5), 24)
			_cyl(e, 0.34, larg + 0.02, Vector3(xx, 0.55, zz), "alu", Vector3(0, 0, PI * 0.5), 20)
			_cyl(e, 0.12, larg + 0.05, Vector3(xx, 0.55, zz), "gris", Vector3(0, 0, PI * 0.5), 10)
			# Écrous de roue
			for k in 8:
				var a: float = TAU * float(k) / 8.0
				_cyl(e, 0.022, larg + 0.07, Vector3(xx, 0.55 + sin(a) * 0.2, zz + cos(a) * 0.2), "inox", Vector3(0, 0, PI * 0.5), 6)
	# Garde-boue avant (noirs, arrondis par trois pans)
	for cote in [-1.0, 1.0]:
		var xg: float = cote * (W * 0.5 - 0.02)
		_b(e, Vector3(0.12, 0.08, 0.7), Vector3(xg, 1.2, -2.55), "noir")
		var av := _b(e, Vector3(0.12, 0.08, 0.5), Vector3(xg, 1.06, -3.05), "noir")
		av.rotation.x = -0.75
		var ar := _b(e, Vector3(0.12, 0.08, 0.5), Vector3(xg, 1.06, -2.05), "noir")
		ar.rotation.x = 0.75


static func _cabine(e: Node3D) -> void:
	var zf: float = Z_AV
	# Pare-chocs blanc enveloppant, grille noire, phares, antibrouillards
	_b(e, Vector3(W + 0.04, 0.55, 0.32), Vector3(0, 0.72, zf - 0.1), "blanc")
	_b(e, Vector3(0.9, 0.22, 0.04), Vector3(0, 0.58, zf - 0.27), "noir")
	_b(e, Vector3(1.3, 0.12, 0.04), Vector3(0, 0.92, zf - 0.27), "noir")
	_b(e, Vector3(W + 0.04, 0.06, 0.34), Vector3(0, 0.43, zf - 0.1), "noir")
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.48, 0.2, 0.05), Vector3(cote * 0.86, 0.8, zf - 0.27), "noir")
		_b(e, Vector3(0.2, 0.13, 0.03), Vector3(cote * 0.76, 0.8, zf - 0.29), "phare")
		_b(e, Vector3(0.16, 0.13, 0.03), Vector3(cote * 0.97, 0.8, zf - 0.29), "phare")
		_cyl(e, 0.05, 0.03, Vector3(cote * 0.9, 0.58, zf - 0.28), "phare", Vector3(PI * 0.5, 0, 0), 10)
		_b(e, Vector3(0.12, 0.05, 0.03), Vector3(cote * 0.95, 0.98, zf - 0.28), "clignotant")
	# Face avant : bas de calandre noir, panneau à chevrons, bandeau noir sous le pare-brise
	_b(e, Vector3(W - 0.1, 0.3, 0.12), Vector3(0, 1.12, zf + 0.02), "noir")
	_b(e, Vector3(1.1, 0.12, 0.03), Vector3(0, 1.14, zf - 0.05), "gris")
	_b(e, Vector3(W - 0.04, 0.55, 0.1), Vector3(0, 1.55, zf + 0.03), "rouge")
	_b(e, Vector3(W - 0.12, 0.53, 0.02), Vector3(0, 1.55, zf - 0.03), "chevrons")
	_b(e, Vector3(W - 0.2, 0.18, 0.06), Vector3(0, 1.91, zf + 0.02), "noir")
	# Grands joues latérales de la face avant (chevrons qui tournent sur le coin)
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.02, 0.55, 0.3), Vector3(cote * (W * 0.5 + 0.01), 1.55, zf + 0.17), "chevrons")
	# Pare-brise légèrement incliné, montants, essuie-glaces
	var pb := _b(e, Vector3(W - 0.18, 0.95, 0.03), Vector3(0, 2.47, zf + 0.08), "vitre")
	pb.rotation.x = -0.1
	for cote in [-1.0, 1.0]:
		var mt := _b(e, Vector3(0.1, 1.0, 0.1), Vector3(cote * (W * 0.5 - 0.05), 2.47, zf + 0.08), "rouge")
		mt.rotation.x = -0.1
		var eg := _b(e, Vector3(0.75, 0.02, 0.02), Vector3(cote * 0.45, 2.03, zf + 0.0), "noir")
		eg.rotation.z = cote * 0.15
	# Traverse haute (bandeau au-dessus du pare-brise) et toit de cabine avant
	_b(e, Vector3(W, 0.16, 0.12), Vector3(0, 3.0, zf + 0.12), "rouge")
	_b(e, Vector3(W, 0.08, 1.75), Vector3(0, 3.05, zf + 0.95), "rouge")
	# Cabine équipage : toit blanc surélevé
	_b(e, Vector3(W, 0.3, 1.45), Vector3(0, 3.18, -1.72), "blanc")
	var chanfrein := _b(e, Vector3(W, 0.06, 0.4), Vector3(0, 3.18, -2.55), "blanc")
	chanfrein.rotation.x = 0.6
	# Flancs de cabine : montants entre les portes, panneau arrière, bas de caisse
	for cote in [-1.0, 1.0]:
		var xs: float = cote * (W * 0.5 - 0.02)
		_b(e, Vector3(0.05, 1.85, 0.14), Vector3(xs, 2.07, -2.78), "rouge")
		_b(e, Vector3(0.05, 1.85, 0.62), Vector3(xs, 2.07, -1.32), "rouge")
		_b(e, Vector3(0.05, 0.16, 3.0), Vector3(xs, 3.0, -2.5), "rouge")
		# Bande jaune et poignée sur le panneau arrière
		_b(e, Vector3(0.01, 0.07, 0.62), Vector3(xs + cote * 0.03, 1.6, -1.32), "jaune")
		_b(e, Vector3(0.03, 0.4, 0.04), Vector3(xs + cote * 0.04, 1.95, -1.15), "alu")
		# Marchepieds (deux marches sous chaque porte)
		for zm in [-3.35, -2.2]:
			_b(e, Vector3(0.3, 0.04, 0.75), Vector3(cote * (W * 0.5 - 0.12), 0.62, zm), "noir")
			_b(e, Vector3(0.22, 0.04, 0.75), Vector3(cote * (W * 0.5 - 0.15), 0.98, zm), "alu")
		# Rétroviseurs sur bras (grand miroir + miroir d'angle)
		_b(e, Vector3(0.32, 0.04, 0.04), Vector3(cote * (W * 0.5 + 0.14), 2.5, zf + 0.2), "noir")
		_b(e, Vector3(0.08, 0.5, 0.26), Vector3(cote * (W * 0.5 + 0.32), 2.3, zf + 0.2), "noir")
		_b(e, Vector3(0.08, 0.22, 0.24), Vector3(cote * (W * 0.5 + 0.32), 1.92, zf + 0.2), "noir")
	# Paroi arrière de la cabine
	_b(e, Vector3(W - 0.04, 1.95, 0.06), Vector3(0, 2.15, Z_CAB), "rouge")


static func _interieur_cabine(e: Node3D) -> void:
	_b(e, Vector3(W - 0.1, 0.06, 2.95), Vector3(0, SOL_CAB, -2.5), "interieur")
	_b(e, Vector3(W - 0.1, 0.04, 2.95), Vector3(0, 2.94, -2.5), "interieur")
	# Planche de bord, volant, compteurs, radio
	_b(e, Vector3(W - 0.15, 0.45, 0.5), Vector3(0, 1.62, Z_AV + 0.42), "interieur")
	_b(e, Vector3(W - 0.2, 0.06, 0.35), Vector3(0, 1.87, Z_AV + 0.5), "siege")
	_cyl(e, 0.23, 0.04, Vector3(-0.6, 2.0, Z_AV + 0.85), "siege", Vector3(1.0, 0, 0), 20)
	_cyl(e, 0.04, 0.4, Vector3(-0.6, 1.88, Z_AV + 0.72), "siege", Vector3(1.0, 0, 0), 8)
	_b(e, Vector3(0.4, 0.14, 0.03), Vector3(-0.6, 1.95, Z_AV + 0.66), "noir")
	_b(e, Vector3(0.32, 0.12, 0.2), Vector3(0.2, 1.78, Z_AV + 0.65), "noir")
	_b(e, Vector3(0.14, 0.05, 0.02), Vector3(0.2, 1.8, Z_AV + 0.54), "eclairage")
	# Sièges avant (conducteur, chef d'agrès)
	for xs in [-0.6, 0.6]:
		_b(e, Vector3(0.5, 0.14, 0.5), Vector3(xs, 1.65, -3.0), "siege")
		_b(e, Vector3(0.5, 0.75, 0.12), Vector3(xs, 2.05, -2.72), "siege")
		_b(e, Vector3(0.28, 0.2, 0.1), Vector3(xs, 2.55, -2.72), "siege")
		_b(e, Vector3(0.3, 0.4, 0.4), Vector3(xs, 1.4, -3.0), "interieur")
	# Banquette de l'équipage, dos à la paroi : 4 places, avec ARI dans les dossiers
	for k in 4:
		var xs2: float = -0.84 + k * 0.56
		_b(e, Vector3(0.48, 0.12, 0.48), Vector3(xs2, 1.65, -1.38), "siege")
		_b(e, Vector3(0.48, 0.8, 0.14), Vector3(xs2, 2.08, -1.1), "siege")
		_cyl(e, 0.09, 0.55, Vector3(xs2, 2.1, -1.2), "bouteille", Vector3.ZERO, 12)
		_b(e, Vector3(0.36, 0.06, 0.04), Vector3(xs2, 2.35, -1.29), "noir")
	_b(e, Vector3(W - 0.15, 0.45, 0.5), Vector3(0, 1.42, -1.38), "interieur")
	# Plafonnier
	_b(e, Vector3(0.4, 0.03, 0.15), Vector3(0, 2.91, -1.9), "eclairage")


static func _caisse(e: Node3D) -> void:
	var lz: float = Z_C1 - Z_C0
	var cz: float = (Z_C0 + Z_C1) * 0.5
	# Noyau central (entre les coffres gauche et droit) : citerne de 3 000 L
	# (il s'arrête avant l'arrière pour laisser la place au coffre de la pompe)
	var lc: float = lz - 0.44
	_b(e, Vector3(W - 1.15, H - 1.0, lc), Vector3(0, (1.0 + H) * 0.5, Z_C0 + lc * 0.5), "rouge")
	# Toit de la caisse et face avant
	_b(e, Vector3(W, 0.06, lz), Vector3(0, H, cz), "gris")
	_b(e, Vector3(W, H - 0.95, 0.06), Vector3(0, (0.95 + H) * 0.5, Z_C0), "rouge")
	for cote in [-1.0, 1.0]:
		var xs: float = cote * (W * 0.5 - 0.02)
		# Bandeau haut (rouge, liseré jaune) au-dessus des rideaux
		_b(e, Vector3(0.05, H - Y_COF1, lz), Vector3(xs, (Y_COF1 + H) * 0.5, cz), "rouge")
		_b(e, Vector3(0.01, 0.08, lz), Vector3(xs + cote * 0.03, H - 0.09, cz), "jaune")
		_b(e, Vector3(0.06, 0.05, lz), Vector3(xs + cote * 0.01, Y_COF1 - 0.02, cz), "alu")
		# Montants entre les coffres (alu)
		var bords: Array = [Z_C0, COFFRES[0][1], COFFRES[1][1], COFFRES[2][1]]
		var debuts: Array = [COFFRES[0][0], COFFRES[1][0], COFFRES[2][0], Z_C1]
		for k in 4:
			var z0: float = bords[k]
			var z1: float = debuts[k]
			_b(e, Vector3(0.06, Y_COF1 - Y_COF0 + 0.1, z1 - z0), Vector3(xs + cote * 0.01, (Y_COF0 + Y_COF1) * 0.5, (z0 + z1) * 0.5), "alu")
		# Coffres bas (devant et derrière la roue arrière), rouges à liseré jaune
		for seg in [[Z_C0, 1.25], [2.75, Z_C1]]:
			var a: float = seg[0]
			var b: float = seg[1]
			_b(e, Vector3(0.05, Y_COF0 - 0.75, b - a), Vector3(xs, (0.75 + Y_COF0) * 0.5, (a + b) * 0.5), "rouge")
			_b(e, Vector3(0.01, 0.07, b - a), Vector3(xs + cote * 0.03, Y_COF0 - 0.08, (a + b) * 0.5), "jaune")
			# Joints des portillons bas et poignées
			var n: int = 2 if b - a > 1.5 else 1
			for j in n:
				var zj: float = a + (b - a) * (float(j) + 0.5) / float(n)
				_b(e, Vector3(0.03, 0.05, 0.22), Vector3(xs + cote * 0.035, 1.12, zj), "alu")
			if n == 2:
				_b(e, Vector3(0.03, Y_COF0 - 0.8, 0.02), Vector3(xs + cote * 0.03, (0.8 + Y_COF0) * 0.5, (a + b) * 0.5), "noir")
		# Passage de roue arrière (alu) et pare-boue
		_b(e, Vector3(0.06, 0.1, 1.5), Vector3(xs + cote * 0.01, Y_COF0 - 0.04, 2.0), "alu")
		_b(e, Vector3(0.05, Y_COF0 - 1.2, 1.5), Vector3(xs, (1.2 + Y_COF0) * 0.5, 2.0), "rouge")


static func _coffres(e: Node3D) -> void:
	# Intérieur de chaque coffre : fond, plancher, plafond, cloisons, éclairage, matériel.
	var profond := 0.56
	for cote in [-1.0, 1.0]:
		for k in 3:
			var z0: float = COFFRES[k][0]
			var z1: float = COFFRES[k][1]
			var zc: float = (z0 + z1) * 0.5
			var lz: float = z1 - z0
			var xb: float = cote * (W * 0.5 - profond)          # fond du coffre
			var xm: float = cote * (W * 0.5 - profond * 0.5)    # milieu
			var hc: float = Y_COF1 - Y_COF0
			_b(e, Vector3(0.03, hc, lz), Vector3(xb, (Y_COF0 + Y_COF1) * 0.5, zc), "coffre")
			_b(e, Vector3(profond, 0.03, lz), Vector3(xm, Y_COF0, zc), "coffre")
			_b(e, Vector3(profond, 0.03, lz), Vector3(xm, Y_COF1, zc), "coffre")
			for zz in [z0, z1]:
				_b(e, Vector3(profond, hc, 0.03), Vector3(xm, (Y_COF0 + Y_COF1) * 0.5, zz), "coffre")
			_b(e, Vector3(0.25, 0.02, lz - 0.2), Vector3(cote * (W * 0.5 - 0.2), Y_COF1 - 0.03, zc), "eclairage")
			var contenu: int = k + (0 if cote > 0.0 else 3)
			_materiel(e, contenu, cote, xb, zc, lz)


## Matériel rangé dans un coffre. 0 : ARI, 1 : tuyaux et lances, 2 : outillage,
## 3 : tuyaux de 110, 4 : aspiration et ventilateur, 5 : extincteurs et balisage.
static func _materiel(e: Node3D, contenu: int, cote: float, xb: float, zc: float, lz: float) -> void:
	var xi: float = xb + cote * 0.02   # contre le fond
	var tablette: float = 2.12
	_b(e, Vector3(0.56, 0.03, lz), Vector3(cote * (W * 0.5 - 0.28), tablette, zc), "coffre")
	match contenu:
		0:
			# Appareils respiratoires isolants : bouteilles jaunes sur dossard noir, masques
			for j in 4:
				var zj: float = zc - lz * 0.5 + 0.2 + j * (lz - 0.4) / 3.0
				_b(e, Vector3(0.05, 0.6, 0.3), Vector3(xi + cote * 0.03, tablette + 0.34, zj), "noir")
				_cyl(e, 0.09, 0.55, Vector3(xi + cote * 0.15, tablette + 0.34, zj), "bouteille", Vector3.ZERO, 12)
				_cyl(e, 0.035, 0.08, Vector3(xi + cote * 0.15, tablette + 0.65, zj), "inox", Vector3.ZERO, 8)
			for j in 4:
				var zj2: float = zc - lz * 0.5 + 0.2 + j * (lz - 0.4) / 3.0
				Geo.sphere(e, 0.11, Vector3(xi + cote * 0.25, Y_COF0 + 0.15, zj2), Color(0.08, 0.08, 0.09))
				_b(e, Vector3(0.05, 0.1, 0.16), Vector3(xi + cote * 0.33, Y_COF0 + 0.15, zj2), "vitre_fumee")
		1:
			# Tuyaux de 70 roulés (en haut) et lances (en bas)
			for j in 4:
				var zj: float = zc - lz * 0.5 + 0.2 + j * (lz - 0.4) / 3.0
				_cyl(e, 0.22, 0.09, Vector3(xi + cote * 0.1, tablette + 0.25, zj), "tuyau", Vector3(0, 0, PI * 0.5), 18)
				_cyl(e, 0.22, 0.09, Vector3(xi + cote * 0.22, tablette + 0.25, zj), "tuyau", Vector3(0, 0, PI * 0.5), 18)
				_cyl(e, 0.05, 0.25, Vector3(xi + cote * 0.3, tablette + 0.25, zj), "inox", Vector3(0, 0, PI * 0.5), 10)
			for j in 3:
				var zl: float = zc - 0.4 + j * 0.4
				_cyl(e, 0.045, 0.55, Vector3(xi + cote * (0.12 + j * 0.1), Y_COF0 + 0.12, zl), "lance", Vector3(PI * 0.5, 0, 0), 10)
				_cyl(e, 0.06, 0.1, Vector3(xi + cote * (0.12 + j * 0.1), Y_COF0 + 0.12, zl - 0.3), "noir", Vector3(PI * 0.5, 0, 0), 10)
			# Division et clés de raccord accrochées au fond
			_b(e, Vector3(0.1, 0.15, 0.3), Vector3(xi + cote * 0.08, Y_COF0 + 0.45, zc + 0.4), "inox")
		2:
			# Outillage : hache, pied-de-biche, masse, extincteur, projecteur
			_b(e, Vector3(0.04, 0.7, 0.05), Vector3(xi + cote * 0.04, tablette + 0.4, zc - 0.45), "siege")
			_b(e, Vector3(0.05, 0.12, 0.22), Vector3(xi + cote * 0.05, tablette + 0.72, zc - 0.4), "rouge")
			_b(e, Vector3(0.04, 0.75, 0.04), Vector3(xi + cote * 0.04, tablette + 0.4, zc - 0.15), "rouge")
			_b(e, Vector3(0.04, 0.6, 0.05), Vector3(xi + cote * 0.04, tablette + 0.35, zc + 0.1), "siege")
			_b(e, Vector3(0.12, 0.12, 0.2), Vector3(xi + cote * 0.08, tablette + 0.68, zc + 0.1), "gris")
			_cyl(e, 0.09, 0.45, Vector3(xi + cote * 0.15, Y_COF0 + 0.24, zc - 0.35), "rouge", Vector3.ZERO, 12)
			_b(e, Vector3(0.3, 0.3, 0.4), Vector3(xi + cote * 0.2, Y_COF0 + 0.17, zc + 0.3), "bouteille")
			_b(e, Vector3(0.02, 0.18, 0.28), Vector3(xi + cote * 0.36, Y_COF0 + 0.2, zc + 0.3), "phare")
		3:
			# Tuyaux de 110 (gros rouleaux) sur deux étages
			for j in 3:
				var zj: float = zc - lz * 0.5 + 0.25 + j * (lz - 0.5) / 2.0
				for niv in [Y_COF0 + 0.3, tablette + 0.3]:
					_cyl(e, 0.27, 0.12, Vector3(xi + cote * 0.1, niv, zj), "tuyau", Vector3(0, 0, PI * 0.5), 20)
					_cyl(e, 0.27, 0.12, Vector3(xi + cote * 0.25, niv, zj), "tuyau", Vector3(0, 0, PI * 0.5), 20)
		4:
			# Tuyaux d'aspiration (noirs, rigides) et ventilateur
			for j in 3:
				_cyl(e, 0.07, lz - 0.1, Vector3(xi + cote * (0.1 + j * 0.15), tablette + 0.12, zc), "noir", Vector3(PI * 0.5, 0, 0), 12)
			_b(e, Vector3(0.45, 0.5, 0.5), Vector3(xi + cote * 0.27, Y_COF0 + 0.26, zc - 0.35), "bouteille")
			_cyl(e, 0.2, 0.05, Vector3(xi + cote * 0.5, Y_COF0 + 0.3, zc - 0.35), "noir", Vector3(0, 0, PI * 0.5), 16)
			_b(e, Vector3(0.4, 0.35, 0.5), Vector3(xi + cote * 0.24, Y_COF0 + 0.19, zc + 0.35), "gris")
		5:
			# Extincteurs, cônes de balisage, trousse
			for j in 3:
				_cyl(e, 0.09, 0.5, Vector3(xi + cote * 0.15, Y_COF0 + 0.27, zc - 0.45 + j * 0.25), "rouge", Vector3.ZERO, 12)
				_cyl(e, 0.03, 0.06, Vector3(xi + cote * 0.15, Y_COF0 + 0.55, zc - 0.45 + j * 0.25), "noir", Vector3.ZERO, 8)
			for j in 3:
				var cone := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.02
				cm.bottom_radius = 0.13
				cm.height = 0.45
				cone.mesh = cm
				cone.material_override = _m["orange"]
				cone.position = Vector3(xi + cote * 0.2, tablette + 0.24 + j * 0.06, zc + 0.3)
				e.add_child(cone)
			_b(e, Vector3(0.25, 0.2, 0.4), Vector3(xi + cote * 0.17, tablette + 0.12, zc - 0.3), "rouge")


static func _arriere(e: Node3D) -> void:
	var zr: float = Z_C1
	# Face arrière : montants à chevrons de chaque côté, coffre central (pompe) fermé par un rideau
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.48, H - 0.95, 0.06), Vector3(cote * (W * 0.5 - 0.24), (0.95 + H) * 0.5, zr), "rouge")
		_b(e, Vector3(0.3, H - 1.05, 0.02), Vector3(cote * (W * 0.5 - 0.17), (1.0 + H) * 0.5, zr + 0.04), "chevrons")
		# Feux arrière, clignotants, catadioptres
		_b(e, Vector3(0.12, 0.3, 0.04), Vector3(cote * (W * 0.5 - 0.1), 0.95, zr + 0.06), "feu_ar")
		_b(e, Vector3(0.12, 0.1, 0.04), Vector3(cote * (W * 0.5 - 0.1), 1.17, zr + 0.06), "clignotant")
	_b(e, Vector3(W - 0.96, 0.5, 0.06), Vector3(0, 1.17, zr), "rouge")
	_b(e, Vector3(W - 0.96, 0.06, 0.06), Vector3(0, Y_COF1 + 0.12, zr), "alu")
	_b(e, Vector3(W - 0.96, H - Y_COF1 - 0.12, 0.06), Vector3(0, (Y_COF1 + 0.15 + H) * 0.5, zr), "rouge")
	# Tableau de pompe derrière le rideau : manomètres, vannes, raccords
	var zp: float = zr - 0.4
	_b(e, Vector3(W - 1.0, Y_COF1 - Y_COF0, 0.04), Vector3(0, (Y_COF0 + Y_COF1) * 0.5, zp), "coffre")
	for k in 3:
		_cyl(e, 0.09, 0.03, Vector3(-0.3 + k * 0.3, 2.5, zp + 0.03), "blanc", Vector3(PI * 0.5, 0, 0), 16)
		_cyl(e, 0.1, 0.02, Vector3(-0.3 + k * 0.3, 2.5, zp + 0.02), "noir", Vector3(PI * 0.5, 0, 0), 16)
	for k in 4:
		_cyl(e, 0.06, 0.18, Vector3(-0.45 + k * 0.3, 1.75, zp + 0.1), "inox", Vector3(PI * 0.5, 0, 0), 12)
		_cyl(e, 0.03, 0.2, Vector3(-0.45 + k * 0.3, 2.05, zp + 0.1), "rouge", Vector3(0, 0, PI * 0.5), 8)
	_b(e, Vector3(0.5, 0.2, 0.03), Vector3(0, 2.2, zp + 0.03), "noir")
	_b(e, Vector3(0.12, 0.05, 0.02), Vector3(-0.1, 2.2, zp + 0.05), "eclairage")
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.03, Y_COF1 - Y_COF0, 0.4), Vector3(cote * (W * 0.5 - 0.5), (Y_COF0 + Y_COF1) * 0.5, zr - 0.2), "coffre")
	_b(e, Vector3(W - 1.0, 0.03, 0.4), Vector3(0, Y_COF0, zr - 0.2), "coffre")
	# Marchepied arrière rabattable et barre d'accroche
	_b(e, Vector3(W - 0.4, 0.05, 0.35), Vector3(0, 0.62, zr + 0.2), "alu")
	_b(e, Vector3(1.2, 0.08, 0.12), Vector3(0, 0.5, zr + 0.06), "noir")
	# Deux dévidoirs mobiles accrochés à l'arrière (roues rouges, tuyau enroulé)
	for cote in [-1.0, 1.0]:
		var xd: float = cote * 0.62
		var zd: float = zr + 0.42
		var yd: float = 1.0
		for flasque in [-0.24, 0.24]:
			_cyl(e, 0.48, 0.04, Vector3(xd + flasque, yd, zd), "rouge", Vector3(0, 0, PI * 0.5), 20)
			_cyl(e, 0.32, 0.05, Vector3(xd + flasque, yd, zd), "noir", Vector3(0, 0, PI * 0.5), 16)
			# Rayons
			for k in 3:
				var rayon := _b(e, Vector3(0.03, 0.9, 0.04), Vector3(xd + flasque * 1.05, yd, zd), "rouge")
				rayon.rotation.x = float(k) * PI / 3.0
		_cyl(e, 0.34, 0.44, Vector3(xd, yd, zd), "tuyau", Vector3(0, 0, PI * 0.5), 20)
		_cyl(e, 0.035, 0.6, Vector3(xd, yd, zd), "inox", Vector3(0, 0, PI * 0.5), 8)
		# Brancards de poussée remontés contre la caisse
		_b(e, Vector3(0.04, 0.04, 0.5), Vector3(xd - 0.24, yd + 0.55, zd - 0.2), "inox")
		_b(e, Vector3(0.04, 0.04, 0.5), Vector3(xd + 0.24, yd + 0.55, zd - 0.2), "inox")
		_b(e, Vector3(0.52, 0.04, 0.04), Vector3(xd, yd + 0.55, zd + 0.05), "inox")
	# Échelle à crochets, debout sur le montant arrière gauche
	var xe: float = -(W * 0.5 - 0.2)
	for xr in [-0.12, 0.12]:
		_b(e, Vector3(0.04, 2.3, 0.05), Vector3(xe + xr, 2.05, zr + 0.13), "alu")
	for k in 8:
		_b(e, Vector3(0.24, 0.03, 0.03), Vector3(xe, 1.0 + k * 0.29, zr + 0.13), "alu")
	_b(e, Vector3(0.26, 0.05, 0.18), Vector3(xe, 3.18, zr + 0.2), "noir")


static func _toit(e: Node3D) -> void:
	# Galerie et échelle trois plans en aluminium, posée sur des supports
	var z0 := -1.95
	var z1 := 3.95
	for zs in [-1.6, 0.8, 3.3]:
		_b(e, Vector3(1.0, 0.18, 0.08), Vector3(0, H + 0.12 if zs > Z_CAB else 3.42, zs), "noir")
	for plan in 3:
		var y: float = H + 0.26 + plan * 0.07
		var demi: float = 0.27 - plan * 0.03
		var za: float = z0 + plan * 0.25
		var zb: float = z1 - plan * 0.4
		for xr in [-demi, demi]:
			_b(e, Vector3(0.05, 0.07, zb - za), Vector3(xr, y, (za + zb) * 0.5), "alu")
		var n: int = int((zb - za) / 0.3)
		for k in n:
			_b(e, Vector3(demi * 2.0, 0.025, 0.03), Vector3(0, y, za + 0.15 + k * 0.3), "alu")
	# Garde-corps latéraux du toit de caisse
	for cote in [-1.0, 1.0]:
		_b(e, Vector3(0.04, 0.04, Z_C1 - Z_C0 - 0.2), Vector3(cote * (W * 0.5 - 0.06), H + 0.2, (Z_C0 + Z_C1) * 0.5), "alu")
		for zs in [Z_C0 + 0.2, 1.4, Z_C1 - 0.2]:
			_b(e, Vector3(0.04, 0.2, 0.04), Vector3(cote * (W * 0.5 - 0.06), H + 0.1, zs), "alu")
	# Projecteur de toit
	_b(e, Vector3(0.35, 0.2, 0.15), Vector3(0.85, H + 0.15, Z_C1 - 0.3), "noir")
	_b(e, Vector3(0.3, 0.15, 0.02), Vector3(0.85, H + 0.15, Z_C1 - 0.22), "phare")


static func _feux_et_gyros(e: Node3D) -> void:
	# Deux gyrophares bleus sur les coins avant du toit, feux bleus à l'arrière,
	# feux de pénétration dans la calandre
	var places: Array = [Vector3(-0.85, 3.17, Z_AV + 0.3), Vector3(0.85, 3.17, Z_AV + 0.3),
		Vector3(-W * 0.5 + 0.15, H + 0.1, Z_C1 - 0.12), Vector3(W * 0.5 - 0.15, H + 0.1, Z_C1 - 0.12),
		Vector3(-0.45, 1.14, Z_AV - 0.05), Vector3(0.45, 1.14, Z_AV - 0.05)]
	for i in places.size():
		var m: StandardMaterial3D = Tex.emissif(Color(0.15, 0.3, 1.0), 0.0)
		e._mats_gyro.append(m)
		var g: Node3D
		if i < 2:
			_cyl(e, 0.1, 0.06, places[i] - Vector3(0, 0.04, 0), "noir", Vector3.ZERO, 12)
			g = _cyl(e, 0.09, 0.2, places[i] + Vector3(0, 0.1, 0), "gris", Vector3.ZERO, 14)
			g.material_override = m
			var lum := OmniLight3D.new()
			lum.light_color = Color(0.2, 0.35, 1.0)
			lum.omni_range = 12.0
			lum.light_energy = 0.0
			g.add_child(lum)
			e._gyros.append(lum)
		else:
			var taille := Vector3(0.16, 0.14, 0.16) if i < 4 else Vector3(0.14, 0.06, 0.03)
			g = Geo.boite_mat(e, taille, places[i], m, false)


static func _inscriptions(e: Node3D) -> void:
	var blanc := Color(1, 1, 1)
	var jaune := Color(1.0, 0.85, 0.1)
	_texte(e, "SAPEURS-POMPIERS", Vector3(0, 2.99, Z_AV + 0.05), PI, 40, 0.005, blanc)
	for cote in [-1.0, 1.0]:
		var xs: float = cote * (W * 0.5 + 0.035)
		var r: float = cote * PI * 0.5
		_texte(e, "SAPEURS-POMPIERS DE TOURAINE", Vector3(xs, 3.02, (Z_C0 + Z_C1) * 0.5), r, 44, 0.0045, blanc)
		_texte(e, "FPT 1", Vector3(xs, 2.3, -1.32), r, 48, 0.005, blanc)
		_texte(e, "JOUÉ-LÈS-TOURS", Vector3(xs, 1.42, -1.32), r, 28, 0.0035, jaune)
		_texte(e, "18 · 112", Vector3(xs, 1.08, 0.2), r, 40, 0.005, blanc)


static func _portes(e: Node3D) -> Dictionary:
	var portes := {}
	# Quatre portes de cabine (charnière à l'avant) : vitre claire devant, fumée à l'arrière
	var defs: Array = [["avant", -3.85, 1.0, "vitre"], ["equipage", -2.71, 1.02, "vitre_fumee"]]
	for d in defs:
		for cote in [-1.0, 1.0]:
			var z0: float = d[1]
			var lz: float = d[2]
			var p := Node3D.new()
			p.position = Vector3(cote * (W * 0.5 - 0.01), 0, z0)
			e.add_child(p)
			_b(p, Vector3(0.06, 1.1, lz), Vector3(0, 1.45, lz * 0.5), "rouge")
			_b(p, Vector3(0.06, 0.12, lz), Vector3(0, 2.88, lz * 0.5), "rouge")
			_b(p, Vector3(0.06, 0.85, 0.08), Vector3(0, 2.42, 0.04), "rouge")
			_b(p, Vector3(0.06, 0.85, 0.08), Vector3(0, 2.42, lz - 0.04), "rouge")
			_b(p, Vector3(0.03, 0.85, lz - 0.14), Vector3(0, 2.42, lz * 0.5), d[3])
			_b(p, Vector3(0.012, 0.07, lz), Vector3(cote * 0.035, 1.6, lz * 0.5), "jaune")
			_b(p, Vector3(0.03, 0.05, 0.2), Vector3(cote * 0.045, 1.85, lz - 0.2), "noir")
			_b(p, Vector3(0.02, 1.0, lz - 0.1), Vector3(-cote * 0.04, 1.5, lz * 0.5), "interieur")
			var cote_txt: String = "gauche" if cote < 0.0 else "droite"
			var nom: String = d[0] + "_" + cote_txt
			var texte: String
			if d[0] == "avant":
				texte = "la porte " + ("conducteur" if cote < 0.0 else "du chef d'agrès")
			else:
				texte = "la porte de l'équipage (" + cote_txt + ")"
			portes[nom] = {"noeud": p, "type": "pivot", "ferme": 0.0, "ouvre": cote * deg_to_rad(75.0), "t": 0.0, "ouvert": false,
				"point": Vector3(cote * (W * 0.5 + 0.4), 1.4, z0 + lz * 0.6), "texte": texte}
	return portes


static func _rideaux(e: Node3D) -> Dictionary:
	var res := {}
	var noms: Array = ["avant", "milieu", "arrière"]
	var hc: float = Y_COF1 - Y_COF0
	for cote in [-1.0, 1.0]:
		for k in 3:
			var z0: float = COFFRES[k][0]
			var z1: float = COFFRES[k][1]
			var n := Node3D.new()
			n.position = Vector3(cote * (W * 0.5 + 0.005), Y_COF1, (z0 + z1) * 0.5)
			e.add_child(n)
			_b(n, Vector3(0.025, hc, z1 - z0), Vector3(0, -hc * 0.5, 0), "rideau")
			_b(n, Vector3(0.05, 0.05, z1 - z0), Vector3(cote * 0.01, -hc + 0.03, 0), "alu")
			_b(n, Vector3(0.04, 0.04, 0.5), Vector3(cote * 0.04, -hc + 0.08, 0), "noir")
			var cote_txt: String = "gauche" if cote < 0.0 else "droit"
			res["coffre_%s_%d" % [cote_txt, k]] = {"noeud": n, "type": "rideau", "t": 0.0, "ouvert": false,
				"point": Vector3(cote * (W * 0.5 + 0.45), 1.5, (z0 + z1) * 0.5), "texte": "le coffre %s %s" % [noms[k], cote_txt]}
	# Coffre de pompe à l'arrière
	var na := Node3D.new()
	na.position = Vector3(0, Y_COF1, Z_C1 + 0.005)
	e.add_child(na)
	_b(na, Vector3(W - 0.96, hc, 0.025), Vector3(0, -hc * 0.5, 0), "rideau")
	_b(na, Vector3(W - 0.96, 0.05, 0.05), Vector3(0, -hc + 0.03, 0.01), "alu")
	res["coffre_pompe"] = {"noeud": na, "type": "rideau", "t": 0.0, "ouvert": false,
		"point": Vector3(0.0, 1.6, Z_C1 + 1.0), "texte": "le coffre de la pompe"}
	return res
