## Petites fonctions pour fabriquer des formes simples (boîtes, cylindres, textes).
## Tout le décor du prototype est construit avec ces formes.
extends RefCounted

static var _materiaux: Dictionary = {}


static func mat(couleur: Color, emission: float = 0.0) -> StandardMaterial3D:
	var cle: String = couleur.to_html() + str(emission)
	if _materiaux.has(cle):
		return _materiaux[cle]
	var m := StandardMaterial3D.new()
	m.albedo_color = couleur
	if couleur.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = couleur
		m.emission_energy_multiplier = emission
	_materiaux[cle] = m
	return m


## Boîte. Si "solide" est vrai, on peut marcher dessus et on ne la traverse pas.
static func boite(parent: Node, taille: Vector3, pos: Vector3, couleur: Color, solide: bool = true) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = taille
	mi.mesh = bm
	mi.material_override = mat(couleur)
	if solide:
		var corps := StaticBody3D.new()
		corps.position = pos
		parent.add_child(corps)
		corps.add_child(mi)
		var cs := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = taille
		cs.shape = forme
		corps.add_child(cs)
		return corps
	mi.position = pos
	parent.add_child(mi)
	return mi


static func cylindre(parent: Node, rayon: float, hauteur: float, pos: Vector3, couleur: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rayon
	cm.bottom_radius = rayon
	cm.height = hauteur
	mi.mesh = cm
	mi.material_override = mat(couleur)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func sphere(parent: Node, rayon: float, pos: Vector3, couleur: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = rayon
	sm.height = rayon * 2.0
	mi.mesh = sm
	mi.material_override = mat(couleur)
	mi.position = pos
	parent.add_child(mi)
	return mi


## Texte flottant dans le monde. "toujours_face" : le texte se tourne vers la caméra.
static func texte(parent: Node, contenu: String, pos: Vector3, taille: int = 48, couleur: Color = Color.WHITE, toujours_face: bool = true) -> Label3D:
	var l := Label3D.new()
	l.text = contenu
	l.font_size = taille
	l.pixel_size = 0.01
	l.modulate = couleur
	l.outline_size = 8
	l.position = pos
	if toujours_face:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	return l


## Mur droit avec des ouvertures (portes, fenêtres).
## axe "x" : le mur suit l'axe x à z = fixe. axe "z" : il suit l'axe z à x = fixe.
## Chaque ouverture : [centre, largeur, y_bas, y_haut] (hauteurs absolues).
static func mur(parent: Node, axe: String, fixe: float, s0: float, s1: float, y0: float, h: float, ep: float, couleur: Color, ouvertures: Array = []) -> void:
	# On regroupe les ouvertures par colonne (même centre) : fenêtres de plusieurs étages.
	var colonnes: Dictionary = {}
	for o in ouvertures:
		var cle: String = "%.2f|%.2f" % [o[0], o[1]]
		if not colonnes.has(cle):
			colonnes[cle] = {"c": float(o[0]), "w": float(o[1]), "trous": []}
		colonnes[cle]["trous"].append([float(o[2]), float(o[3])])
	var liste: Array = colonnes.values()
	liste.sort_custom(func(k1, k2): return k1["c"] < k2["c"])
	var cur: float = s0
	for col in liste:
		var c: float = col["c"]
		var w: float = col["w"]
		var a: float = c - w * 0.5
		var b: float = c + w * 0.5
		if a > cur:
			_segment(parent, axe, fixe, cur, a, y0, y0 + h, ep, couleur)
		var trous: Array = col["trous"]
		trous.sort_custom(func(t1, t2): return t1[0] < t2[0])
		var y: float = y0
		for t in trous:
			var yb: float = t[0]
			var yh: float = t[1]
			if yb > y:
				_segment(parent, axe, fixe, a, b, y, yb, ep, couleur)
			y = maxf(y, yh)
		if y < y0 + h:
			_segment(parent, axe, fixe, a, b, y, y0 + h, ep, couleur)
		cur = b
	if s1 > cur:
		_segment(parent, axe, fixe, cur, s1, y0, y0 + h, ep, couleur)


static func _segment(parent: Node, axe: String, fixe: float, a: float, b: float, ya: float, yb: float, ep: float, couleur: Color) -> void:
	var longueur: float = b - a
	var hauteur: float = yb - ya
	if longueur <= 0.01 or hauteur <= 0.01:
		return
	var centre: float = (a + b) * 0.5
	var cy: float = (ya + yb) * 0.5
	if axe == "x":
		boite(parent, Vector3(longueur, hauteur, ep), Vector3(centre, cy, fixe), couleur)
	else:
		boite(parent, Vector3(ep, hauteur, longueur), Vector3(fixe, cy, centre), couleur)
