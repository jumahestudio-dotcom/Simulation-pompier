## Voitures aux formes arrondies (aucune marque) : citadine, berline, break, monospace, utilitaire.
## La carrosserie est « sculptée » par sections successives de l'avant à l'arrière, avec des
## coins arrondis : nez plongeant, capot incliné, pare-brise couché, passages de roue,
## toit galbé, phares et feux. Les maillages sont calculés une fois par modèle puis réutilisés.
##   VoitureModele.instancier(parent, type, couleur)        voiture qui roule (nœuds)
##   VoitureModele.garer(type, couleur, position, base)      voiture garée (fusionnée dans Lot)
## L'avant est vers -z, les roues posées à y = 0.
extends RefCounted

const Tex = preload("res://scripts/textures.gd")
const Geo = preload("res://scripts/geo.gd")

const TYPES: Array = ["citadine", "berline", "break", "monospace", "utilitaire", "citadine", "berline"]

## Gabarits : longueur, demi-largeur, roues (z avant, z arrière), fin du capot, début et fin du toit,
## bas de la lunette arrière, hauteur du toit, ligne de ceinture, hauteur du nez, garde au sol.
const GABARITS: Dictionary = {
	"citadine": {"av": -1.95, "ar": 1.95, "w": 0.84, "roues": [-1.27, 1.22], "capot": -0.85, "toit0": -0.12, "toit1": 1.45, "lunette": 1.88, "h": 1.47, "ceinture": 0.93, "nez": 0.7, "sol": 0.3},
	"berline": {"av": -2.25, "ar": 2.25, "w": 0.9, "roues": [-1.42, 1.38], "capot": -0.78, "toit0": 0.05, "toit1": 0.95, "lunette": 1.72, "h": 1.43, "ceinture": 0.94, "nez": 0.72, "sol": 0.3},
	"break": {"av": -2.33, "ar": 2.35, "w": 0.9, "roues": [-1.45, 1.45], "capot": -0.82, "toit0": 0.0, "toit1": 2.02, "lunette": 2.27, "h": 1.47, "ceinture": 0.95, "nez": 0.72, "sol": 0.3},
	"monospace": {"av": -2.25, "ar": 2.25, "w": 0.92, "roues": [-1.4, 1.38], "capot": -1.1, "toit0": -0.28, "toit1": 1.85, "lunette": 2.15, "h": 1.66, "ceinture": 1.04, "nez": 0.82, "sol": 0.38},
	"utilitaire": {"av": -2.2, "ar": 2.2, "w": 0.92, "roues": [-1.38, 1.45], "capot": -1.32, "toit0": -0.62, "toit1": 2.15, "lunette": 2.19, "h": 1.84, "ceinture": 1.05, "nez": 0.8, "sol": 0.33},
}

const R_ROUE := 0.32

static var _cache: Dictionary = {}


# ---------------------------------------------------------------------------
# Profil de la voiture
# ---------------------------------------------------------------------------

static func _lerp_cles(cles: Array, z: float) -> float:
	if z <= float(cles[0][0]):
		return cles[0][1]
	for i in cles.size() - 1:
		var a: Array = cles[i]
		var b: Array = cles[i + 1]
		if z <= float(b[0]):
			var t: float = (z - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			t = t * t * (3.0 - 2.0 * t)
			return lerpf(float(a[1]), float(b[1]), t)
	return cles[cles.size() - 1][1]


## Section de caisse à la position z : [y bas, y haut, demi-largeur bas, demi-largeur haut]
static func _section_caisse(g: Dictionary, z: float) -> Array:
	var av: float = g["av"]
	var ar: float = g["ar"]
	var w: float = g["w"]
	var sol: float = g["sol"]
	var ybas: float = sol
	for zr in g["roues"]:
		var u: float = (z - float(zr)) / (R_ROUE + 0.1)
		if absf(u) < 1.0:
			ybas = maxf(ybas, 0.36 + (R_ROUE + 0.05) * sqrt(1.0 - u * u) - 0.0)
	# Pare-chocs : le bas remonte un peu aux extrémités
	ybas = maxf(ybas, _lerp_cles([[av, sol + 0.12], [av + 0.35, sol], [ar - 0.35, sol], [ar, sol + 0.14]], z))
	var cap: float = g["capot"]
	var ceinture: float = g["ceinture"]
	var yh: float = _lerp_cles([[av, float(g["nez"]) - 0.06], [av + 0.12, g["nez"]], [cap, ceinture - 0.01], [float(g["lunette"]), ceinture + 0.01], [ar - 0.12, ceinture - 0.02], [ar, ceinture - 0.1]], z)
	# En plan, l'avant et l'arrière s'arrondissent
	var largeur: float = _lerp_cles([[av, w * 0.82], [av + 0.25, w * 0.97], [av + 0.6, w], [ar - 0.5, w], [ar - 0.15, w * 0.96], [ar, w * 0.84]], z)
	return [ybas, yh, largeur, largeur * 0.93]


## Section de l'habitacle vitré : [y bas, y haut, demi-largeur bas, demi-largeur haut], ou [] hors habitacle
static func _section_habitacle(g: Dictionary, z: float) -> Array:
	var cap: float = g["capot"]
	var lun: float = g["lunette"]
	if z < cap or z > lun:
		return []
	var ceinture: float = g["ceinture"]
	var h: float = g["h"]
	var yh: float = _lerp_cles([[cap, ceinture + 0.02], [float(g["toit0"]), h], [float(g["toit1"]), h - 0.02], [lun, ceinture + 0.06]], z)
	var w: float = g["w"]
	return [ceinture - 0.03, yh, w * 0.93, w * 0.76]


# ---------------------------------------------------------------------------
# Géométrie
# ---------------------------------------------------------------------------

## Anneau en rectangle aux coins arrondis (sens trigonométrique vu de +z).
static func _anneau(ybas: float, yhaut: float, lb: float, lh: float, rayon: float) -> Array:
	var pts: Array = []
	var r: float = minf(rayon, (yhaut - ybas) * 0.45)
	var coins: Array = [
		[Vector2(lb - r, ybas + r), -PI * 0.5],    # bas droit
		[Vector2(lh - r, yhaut - r), 0.0],         # haut droit
		[Vector2(-lh + r, yhaut - r), PI * 0.5],   # haut gauche
		[Vector2(-lb + r, ybas + r), PI],          # bas gauche
	]
	for c in coins:
		var centre: Vector2 = c[0]
		var a0: float = c[1]
		for k in 4:
			var a: float = a0 + (PI * 0.5) * float(k) / 3.0
			var dir := Vector2(cos(a), sin(a))
			pts.append([centre + dir * r, dir])
	return pts


static func _loft_z(st: SurfaceTool, sections: Array, rayon: float) -> void:
	# sections : [[z, ybas, yhaut, lb, lh], ...]
	var base: int = _sommets(st)
	var nb: int = 0
	for s in sections:
		var z: float = s[0]
		var pts: Array = _anneau(s[1], s[2], s[3], s[4], rayon)
		nb = pts.size()
		for p in pts:
			var v: Vector2 = p[0]
			var d: Vector2 = p[1]
			st.set_normal(Vector3(d.x, d.y, 0).normalized())
			st.add_vertex(Vector3(v.x, v.y, z))
	_compte[st] = base + sections.size() * nb
	for i in sections.size() - 1:
		for j in nb:
			var j2 := (j + 1) % nb
			var a := base + i * nb + j
			var b := base + i * nb + j2
			var c := base + (i + 1) * nb + j2
			var d := base + (i + 1) * nb + j
			st.add_index(a); st.add_index(d); st.add_index(b)
			st.add_index(b); st.add_index(d); st.add_index(c)
	# Couvercles avant et arrière
	for bout in [0, sections.size() - 1]:
		var s: Array = sections[bout]
		var centre := Vector3(0, (float(s[1]) + float(s[2])) * 0.5, s[0])
		var ic: int = _sommets(st)
		st.set_normal(Vector3(0, 0, -1 if bout == 0 else 1))
		st.add_vertex(centre)
		_compte[st] = ic + 1
		for j in nb:
			var j2 := (j + 1) % nb
			if bout == 0:
				st.add_index(base + j); st.add_index(base + j2); st.add_index(ic)
			else:
				st.add_index(base + bout * nb + j2); st.add_index(base + bout * nb + j); st.add_index(ic)


static var _compte: Dictionary = {}


static func _sommets(st: SurfaceTool) -> int:
	return _compte.get(st, 0)


static func _boite(st: SurfaceTool, taille: Vector3, centre: Vector3, base: Basis = Basis.IDENTITY) -> void:
	var h := taille * 0.5
	var faces := [
		[Vector3.RIGHT, Vector3.BACK, Vector3.UP], [Vector3.LEFT, Vector3.FORWARD, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK], [Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD],
		[Vector3.BACK, Vector3.LEFT, Vector3.UP], [Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
	]
	var n0: int = _sommets(st)
	for f in faces:
		var nl: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var c := nl * h
		var coins := [c - u * h - v * h, c + u * h - v * h, c + u * h + v * h, c - u * h + v * h]
		for k in 4:
			st.set_normal(base * nl)
			st.add_vertex(centre + base * coins[k])
		st.add_index(n0); st.add_index(n0 + 1); st.add_index(n0 + 2)
		st.add_index(n0); st.add_index(n0 + 2); st.add_index(n0 + 3)
		n0 += 4
	_compte[st] = n0


## Cylindre couché selon x (roue) : rayon, largeur, centre. Fait à partir du cylindre de Godot.
static var _cyl_arrays: Dictionary = {}


static func _roue(st: SurfaceTool, r: float, larg: float, centre: Vector3, cotes: int = 18) -> void:
	if not _cyl_arrays.has(cotes):
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.0
		cm.height = 1.0
		cm.radial_segments = cotes
		cm.rings = 1
		_cyl_arrays[cotes] = cm.get_mesh_arrays()
	var arr: Array = _cyl_arrays[cotes]
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var base := Basis(Vector3.FORWARD, PI * 0.5)   # axe du cylindre (y) couché selon x
	var ech := Vector3(r, larg, r)
	var inv := Vector3(1.0 / r, 1.0 / larg, 1.0 / r)
	var n0: int = _sommets(st)
	for k in vs.size():
		st.set_normal((base * (ns[k] * inv)).normalized())
		st.add_vertex(centre + base * (vs[k] * ech))
	for k in idx.size():
		st.add_index(n0 + idx[k])
	_compte[st] = n0 + vs.size()


# ---------------------------------------------------------------------------
# Modèles
# ---------------------------------------------------------------------------

## Tableaux de maillage (surface arrays) d'un modèle : peinture, vitres, noir (pneus, bas de caisse), jantes, phares, feux.
static func maillages(type: String) -> Dictionary:
	if _cache.has(type):
		return _cache[type]
	var g: Dictionary = GABARITS[type]
	var sts: Dictionary = {}
	for k in ["peinture", "vitres", "noir", "jantes", "phares", "feux"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts[k] = st
		_compte[st] = 0
	var av: float = g["av"]
	var ar: float = g["ar"]
	var w: float = g["w"]
	# Caisse : une section tous les 10 cm (plus serré aux bouts)
	var secs: Array = []
	var z: float = av
	while z < ar - 0.001:
		var s := _section_caisse(g, z)
		secs.append([z, s[0], s[1], s[2], s[3]])
		z += 0.05 if (z < av + 0.3 or z > ar - 0.3) else 0.1
	var sf := _section_caisse(g, ar)
	secs.append([ar, sf[0], sf[1], sf[2], sf[3]])
	_loft_z(sts["peinture"], secs, 0.12)
	# Habitacle vitré et toit peint par-dessus
	var hab: Array = []
	var toit: Array = []
	z = float(g["capot"])
	var lun: float = g["lunette"]
	var t0: float = g["toit0"]
	var t1: float = g["toit1"]
	while z <= lun + 0.001:
		var s2 := _section_habitacle(g, z)
		if not s2.is_empty():
			hab.append([z, s2[0], s2[1], s2[2], s2[3]])
			if z >= t0 - 0.05 and z <= t1 + 0.05:
				toit.append([z, float(s2[1]) - 0.05, float(s2[1]) + 0.012, float(s2[3]) + 0.02, float(s2[3]) - 0.02])
		z += 0.05
	_loft_z(sts["vitres"], hab, 0.1)
	if toit.size() > 1:
		_loft_z(sts["peinture"], toit, 0.06)
	# Montants (pied milieu) et bas de caisse noir, pare-chocs, calandre, rétroviseurs
	var zb: float = lerpf(t0, t1, 0.42)
	for sx in [-1.0, 1.0]:
		var s3 := _section_habitacle(g, zb)
		if not s3.is_empty():
			var hy: float = float(s3[1]) - float(s3[0])
			_boite(sts["peinture"], Vector3(0.03, hy - 0.1, 0.12), Vector3(sx * (lerpf(float(s3[2]), float(s3[3]), 0.5) + 0.006), (float(s3[0]) + float(s3[1])) * 0.5 - 0.02, zb), Basis(Vector3.FORWARD, -sx * 0.1))
		_boite(sts["noir"], Vector3(0.06, 0.1, 0.16), Vector3(sx * (w + 0.06), float(g["ceinture"]) + 0.05, float(g["capot"]) + 0.12))
		_boite(sts["peinture"], Vector3(0.1, 0.12, 0.08), Vector3(sx * (w + 0.1), float(g["ceinture"]) + 0.06, float(g["capot"]) + 0.12))
	var nez: float = g["nez"]
	var sol: float = g["sol"]
	_boite(sts["noir"], Vector3(w * 1.6, 0.09, 0.06), Vector3(0, sol + 0.18, av + 0.02))
	_boite(sts["noir"], Vector3(w * 0.9, 0.14, 0.04), Vector3(0, nez - 0.2, av + 0.03))
	_boite(sts["noir"], Vector3(w * 1.6, 0.08, 0.06), Vector3(0, sol + 0.2, ar - 0.02))
	# Plaques d'immatriculation (sans numéro)
	_boite(sts["phares"], Vector3(0.48, 0.1, 0.012), Vector3(0, sol + 0.32, av + 0.0))
	_boite(sts["phares"], Vector3(0.48, 0.1, 0.012), Vector3(0, sol + 0.42, ar + 0.004))
	# Phares en biseau et feux arrière qui enveloppent le coin
	for sx in [-1.0, 1.0]:
		_boite(sts["phares"], Vector3(0.3, 0.1, 0.03), Vector3(sx * w * 0.7, nez - 0.08, av + 0.07), Basis(Vector3.UP, sx * 0.35) * Basis(Vector3.FORWARD, sx * 0.08))
		_boite(sts["feux"], Vector3(0.26, 0.11, 0.03), Vector3(sx * w * 0.72, float(g["ceinture"]) - 0.08, ar - 0.06), Basis(Vector3.UP, -sx * 0.4))
	# Roues : pneu, jante, moyeu
	for zr in g["roues"]:
		for sx in [-1.0, 1.0]:
			var c := Vector3(sx * (w - 0.12), R_ROUE, zr)
			_roue(sts["noir"], R_ROUE, 0.21, c)
			_roue(sts["jantes"], R_ROUE * 0.62, 0.215, c, 14)
			_roue(sts["noir"], R_ROUE * 0.18, 0.22, c, 8)
			# Passage de roue sombre (fond)
			_roue(sts["noir"], R_ROUE + 0.04, 0.12, Vector3(sx * (w - 0.24), R_ROUE + 0.02, zr), 14)
	var res: Dictionary = {}
	for k in sts:
		res[k] = sts[k].commit_to_arrays()
		_compte.erase(sts[k])
	_cache[type] = res
	return res


static var _cache_mesh: Dictionary = {}


## Mêmes maillages sous forme d'ArrayMesh (pour les voitures en nœuds).
static func meshes(type: String) -> Dictionary:
	if not _cache_mesh.has(type):
		var res: Dictionary = {}
		var arrs := maillages(type)
		for k in arrs:
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrs[k])
			res[k] = am
		_cache_mesh[type] = res
	return _cache_mesh[type]


static func _materiaux(couleur: Color) -> Dictionary:
	var vitre := Tex.vitre()
	return {
		"peinture": Tex.carrosserie(couleur), "vitres": vitre,
		"noir": Geo.mat(Color(0.05, 0.05, 0.055)), "jantes": _jante(),
		"phares": Tex.emissif(Color(1.0, 0.98, 0.9), 0.35), "feux": Tex.emissif(Color(0.75, 0.04, 0.04), 0.4),
	}


static var _mat_jante: StandardMaterial3D = null


static func _jante() -> StandardMaterial3D:
	if _mat_jante == null:
		_mat_jante = StandardMaterial3D.new()
		_mat_jante.albedo_color = Color(0.48, 0.49, 0.5)
		_mat_jante.metallic = 0.6
		_mat_jante.roughness = 0.3
	return _mat_jante


## Voiture complète en nœuds (pour le trafic). Renvoie le nœud créé.
static func instancier(parent: Node3D, type: String, couleur: Color) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var m := meshes(type)
	var mats := _materiaux(couleur)
	for k in m:
		var mi := MeshInstance3D.new()
		mi.mesh = m[k]
		mi.material_override = mats[k]
		n.add_child(mi)
	return n


## Voiture garée : fusionnée avec le décor (Lot), pour en mettre des centaines sans ralentir.
static func garer(lot, type: String, couleur: Color, pos: Vector3, base: Basis) -> void:
	var m := maillages(type)
	var mats := _materiaux(couleur)
	for k in m:
		lot.maillage(m[k], pos, base, mats[k])


static func type_au_hasard(rng: RandomNumberGenerator) -> String:
	return TYPES[rng.randi() % TYPES.size()]
