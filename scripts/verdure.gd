## Touffes d'herbe et fleurs posées sur les pelouses, les jardins et les bas-côtés.
## On déclare des zones pendant la construction (Verdure.pelouse), puis Verdure.finir pose
## des milliers de touffes en quelques « MultiMesh » par case de 40 m. Elles ne sont dessinées
## que près de la caméra (moins de 70 m), ce qui garde le jeu fluide.
extends RefCounted

const Tex = preload("res://scripts/textures.gd")
const Carte = preload("res://scripts/carte.gd")
const CASE := 40.0
const DISTANCE := 70.0

static var _zones: Array = []
static var _exclues: Array = []
static var _maillage: ArrayMesh = null


## Une zone d'herbe : rectangle (x, z), nombre de touffes par m², part de touffes fleuries, hauteur du sol, taille.
static func pelouse(r: Rect2, densite: float = 0.5, fleurs: float = 0.06, y: float = 0.0, taille: float = 1.0) -> void:
	_zones.append({"r": r, "d": densite, "f": fleurs, "y": y, "t": taille})


## Rectangle (x, z) où l'on ne pose pas d'herbe (allée, terrasse, piscine, parking…).
static func exclure(r: Rect2) -> void:
	_exclues.append(r)


## Vrai si le point est sur une chaussée du plan ou dans une zone exclue.
static func _interdit(p: Vector2) -> bool:
	for r in _exclues:
		if (r as Rect2).has_point(p):
			return true
	for ar in Carte.ARETES:
		var a: Vector3 = Carte.NOEUDS[ar[0]]
		var b: Vector3 = Carte.NOEUDS[ar[1]]
		var demi: float = Carte.largeur_arete(ar[0], ar[1]) * 0.5 + 1.0
		if p.x < minf(a.x, b.x) - demi or p.x > maxf(a.x, b.x) + demi or p.y < minf(a.z, b.z) - demi or p.y > maxf(a.z, b.z) + demi:
			continue
		var q := Geometry2D.get_closest_point_to_segment(p, Vector2(a.x, a.z), Vector2(b.x, b.z))
		if q.distance_to(p) < demi:
			return true
	return false


## Touffe : trois cartes croisées de 50 cm, éclairées comme le sol (normale vers le haut).
static func _touffe() -> ArrayMesh:
	if _maillage != null:
		return _maillage
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 0
	for k in 3:
		var a := k * PI / 3.0
		var u := Vector3(cos(a), 0, sin(a)) * 0.26
		var h := Vector3(0, 0.36, 0)
		var coins := [-u, u, u + h, -u + h]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for i in 4:
			st.set_normal(Vector3.UP)
			st.set_color(Color.WHITE)
			st.set_uv(uvs[i])
			st.add_vertex(coins[i])
		st.add_index(n); st.add_index(n + 1); st.add_index(n + 2)
		st.add_index(n); st.add_index(n + 2); st.add_index(n + 3)
		n += 4
	_maillage = st.commit()
	return _maillage


static func finir(racine: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var cases := {}
	for z in _zones:
		var r: Rect2 = z["r"]
		var nb := int(r.get_area() * float(z["d"]))
		for i in nb:
			var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
			if _interdit(p):
				continue
			var fleur := rng.randf() < float(z["f"])
			var cle := "%d|%d|%d" % [int(floor(p.x / CASE)), int(floor(p.y / CASE)), 1 if fleur else 0]
			if not cases.has(cle):
				cases[cle] = []
			var s: float = float(z["t"]) * rng.randf_range(0.6, 1.35)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s))
			var g := rng.randf_range(0.8, 1.15)
			cases[cle].append([Transform3D(b, Vector3(p.x, float(z["y"]), p.y)), Color(g * rng.randf_range(0.95, 1.08), g, g * 0.95)])
	var total := 0
	for cle in cases:
		total += (cases[cle] as Array).size()
	print("Verdure : %d touffes d'herbe en %d groupes" % [total, cases.size()])
	var mat_h := Tex.mat_cartes(Tex.touffe(false), Color(0.72, 0.74, 0.66), 0.4)
	var mat_f := Tex.mat_cartes(Tex.touffe(true), Color(0.72, 0.74, 0.66), 0.4)
	for cle in cases:
		var l: Array = cases[cle]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _touffe()
		mm.instance_count = l.size()
		for i in l.size():
			mm.set_instance_transform(i, l[i][0])
			mm.set_instance_color(i, l[i][1])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat_f if String(cle).ends_with("|1") else mat_h
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = DISTANCE
		mi.visibility_range_end_margin = 10.0
		racine.add_child(mi)
	_zones.clear()
	_exclues.clear()
