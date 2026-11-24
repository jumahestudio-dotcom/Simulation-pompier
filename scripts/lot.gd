## Regroupe beaucoup de petites formes (détails de façades, mobilier urbain…) en quelques gros
## maillages : un par matériau et par case de 160 m. La ville peut ainsi avoir des milliers de
## détails sans ralentir le jeu. Ces formes sont décoratives : on ne se cogne pas dedans.
##   Lot.boite(taille, centre, materiau, base)   base : orientation (Basis), facultative
##   Lot.finir(racine)                            à appeler une fois, à la fin de la construction
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const CASE := 160.0

static var _paquets: Dictionary = {}
static var _gabarits: Dictionary = {}


static func _paquet(m: Material, pos: Vector3) -> Dictionary:
	var cle := "%d|%d|%d" % [m.get_instance_id(), int(floor(pos.x / CASE)), int(floor(pos.z / CASE))]
	if not _paquets.has(cle):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_paquets[cle] = {"mat": m, "st": st, "n": 0}
	return _paquets[cle]


static func couleur(c: Color, emission: float = 0.0) -> Material:
	return Geo.mat(c, emission)


## Une boîte de dimensions "taille" (dans son propre repère), centrée en "centre".
static func boite(taille: Vector3, centre: Vector3, m: Material, base: Basis = Basis.IDENTITY) -> void:
	var p := _paquet(m, centre)
	var st: SurfaceTool = p["st"]
	var h := taille * 0.5
	# Pour chaque face : normale, puis deux axes qui la parcourent.
	var faces := [
		[Vector3.RIGHT, Vector3.BACK, Vector3.UP], [Vector3.LEFT, Vector3.FORWARD, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK], [Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD],
		[Vector3.BACK, Vector3.LEFT, Vector3.UP], [Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
	]
	var n0: int = p["n"]
	for f in faces:
		var nl: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var nm: Vector3 = base * nl
		var c := nl * h
		var du := u * h
		var dv := v * h
		var coins := [c - du - dv, c + du - dv, c + du + dv, c - du + dv]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for k in 4:
			st.set_normal(nm)
			st.set_uv(uvs[k])
			st.add_vertex(centre + base * coins[k])
		# Ordre des sommets : sens horaire vu de l'extérieur (face visible pour Godot)
		st.add_index(n0); st.add_index(n0 + 1); st.add_index(n0 + 2)
		st.add_index(n0); st.add_index(n0 + 2); st.add_index(n0 + 3)
		n0 += 4
	p["n"] = n0


## Boîte avec une couleur unie.
static func boite_c(taille: Vector3, centre: Vector3, c: Color, base: Basis = Basis.IDENTITY) -> void:
	boite(taille, centre, Geo.mat(c), base)


## Un toit à deux pans : "largeur" en travers, "longueur" le long du faîtage (axe z local).
## "pied" : centre de la base du toit.
static func toit(largeur: float, hauteur: float, longueur: float, pied: Vector3, m: Material, base: Basis = Basis.IDENTITY) -> void:
	var p := _paquet(m, pied)
	var st: SurfaceTool = p["st"]
	var lx := largeur * 0.5
	var lz := longueur * 0.5
	var a := Vector3(-lx, 0, -lz)
	var b := Vector3(lx, 0, -lz)
	var s := Vector3(0, hauteur, -lz)
	var a2 := Vector3(-lx, 0, lz)
	var b2 := Vector3(lx, 0, lz)
	var s2 := Vector3(0, hauteur, lz)
	var n0: int = p["n"]
	var quads := [[a, a2, s2, s], [b2, b, s, s2]]
	for q in quads:
		var nm: Vector3 = (q[1] - q[0]).cross(q[3] - q[0]).normalized()
		for k in 4:
			st.set_normal(base * nm)
			st.set_uv(Vector2(k % 2, k / 2))
			st.add_vertex(pied + base * q[k])
		st.add_index(n0); st.add_index(n0 + 2); st.add_index(n0 + 1)
		st.add_index(n0); st.add_index(n0 + 3); st.add_index(n0 + 2)
		n0 += 4
	var tris := [[b, a, s], [a2, b2, s2]]
	for t in tris:
		var nm2: Vector3 = (t[1] - t[0]).cross(t[2] - t[0]).normalized()
		for k in 3:
			st.set_normal(base * nm2)
			st.set_uv(Vector2(0.5 * k, 1.0 - 0.5 * k))
			st.add_vertex(pied + base * t[k])
		st.add_index(n0); st.add_index(n0 + 2); st.add_index(n0 + 1)
		n0 += 3
	p["n"] = n0


static func _gabarit(nom: String) -> Array:
	if not _gabarits.has(nom):
		var m: PrimitiveMesh
		if nom == "cyl_lo":
			var c3 := CylinderMesh.new()
			c3.top_radius = 1.0
			c3.bottom_radius = 1.0
			c3.height = 1.0
			c3.radial_segments = 5
			c3.rings = 1
			c3.cap_top = false
			c3.cap_bottom = false
			m = c3
		elif nom == "cone_lo":
			var c4 := CylinderMesh.new()
			c4.top_radius = 0.0
			c4.bottom_radius = 1.0
			c4.height = 1.0
			c4.radial_segments = 7
			c4.rings = 1
			c4.cap_top = false
			m = c4
		elif nom == "sph_lo":
			var s2 := SphereMesh.new()
			s2.radius = 1.0
			s2.height = 2.0
			s2.radial_segments = 7
			s2.rings = 4
			m = s2
		elif nom == "cyl":
			var c := CylinderMesh.new()
			c.top_radius = 1.0
			c.bottom_radius = 1.0
			c.height = 1.0
			c.radial_segments = 10
			c.rings = 1
			m = c
		elif nom == "cone":
			var c2 := CylinderMesh.new()
			c2.top_radius = 0.0
			c2.bottom_radius = 1.0
			c2.height = 1.0
			c2.radial_segments = 10
			c2.rings = 1
			m = c2
		else:
			var s := SphereMesh.new()
			s.radius = 1.0
			s.height = 2.0
			s.radial_segments = 10
			s.rings = 6
			m = s
		_gabarits[nom] = m.get_mesh_arrays()
	return _gabarits[nom]


static func _forme(nom: String, echelle: Vector3, centre: Vector3, m: Material, base: Basis) -> void:
	var p := _paquet(m, centre)
	var st: SurfaceTool = p["st"]
	var arr: Array = _gabarit(nom)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var n0: int = p["n"]
	var inv := Vector3(1.0 / echelle.x, 1.0 / echelle.y, 1.0 / echelle.z)
	for k in vs.size():
		st.set_normal((base * (ns[k] * inv)).normalized())
		st.set_uv(Vector2.ZERO)
		st.add_vertex(centre + base * (vs[k] * echelle))
	for k in idx.size():
		st.add_index(n0 + idx[k])
	p["n"] = n0 + vs.size()


## Cylindre vertical (ou orienté par "base") : rayon, hauteur, centre.
static func cylindre(rayon: float, hauteur: float, centre: Vector3, m: Material, base: Basis = Basis.IDENTITY) -> void:
	_forme("cyl", Vector3(rayon, hauteur, rayon), centre, m, base)


static func cone(rayon: float, hauteur: float, centre: Vector3, m: Material) -> void:
	_forme("cone", Vector3(rayon, hauteur, rayon), centre, m, Basis.IDENTITY)


## Versions simplifiées pour les forêts (beaucoup d'arbres, vus de loin).
static func arbre_feuillu(pos: Vector3, taille: float, feuillage: Material, tronc: Material) -> void:
	_forme("cyl_lo", Vector3(0.25 * taille, 4.0 * taille, 0.25 * taille), pos + Vector3(0, 2.0 * taille, 0), tronc, Basis.IDENTITY)
	_forme("sph_lo", Vector3(2.6, 2.3, 2.6) * taille, pos + Vector3(0, 5.6 * taille, 0), feuillage, Basis.IDENTITY)


static func arbre_conifere(pos: Vector3, taille: float, feuillage: Material, tronc: Material) -> void:
	_forme("cyl_lo", Vector3(0.2 * taille, 2.0 * taille, 0.2 * taille), pos + Vector3(0, 1.0 * taille, 0), tronc, Basis.IDENTITY)
	_forme("cone_lo", Vector3(2.0, 7.0, 2.0) * taille, pos + Vector3(0, 5.0 * taille, 0), feuillage, Basis.IDENTITY)
	_forme("cone_lo", Vector3(1.5, 4.5, 1.5) * taille, pos + Vector3(0, 8.0 * taille, 0), feuillage, Basis.IDENTITY)


static func sphere(rayon: float, centre: Vector3, m: Material, aplati: float = 1.0) -> void:
	_forme("sph", Vector3(rayon, rayon * aplati, rayon), centre, m, Basis.IDENTITY)


## Copie un maillage déjà fait (première surface), déplacé et orienté.
static func maillage(arr: Array, centre: Vector3, base: Basis, mat: Material) -> void:
	var p := _paquet(mat, centre)
	var st: SurfaceTool = p["st"]
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var n0: int = p["n"]
	for k in vs.size():
		st.set_normal(base * ns[k])
		st.set_uv(Vector2.ZERO)
		st.add_vertex(centre + base * vs[k])
	for k in idx.size():
		st.add_index(n0 + idx[k])
	p["n"] = n0 + vs.size()


## Construit les maillages et les ajoute à la scène.
static func finir(racine: Node3D) -> void:
	for cle in _paquets:
		var p: Dictionary = _paquets[cle]
		var st: SurfaceTool = p["st"]
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = p["mat"]
		racine.add_child(mi)
	_paquets.clear()


## Une carte (rectangle plat texturé) : coins dans l'ordre bas-gauche, bas-droite, haut-droite, haut-gauche.
## "normale" : direction d'éclairage commune aux quatre coins ; "teinte" : légère variation de couleur.
static func carte(coins: Array, normale: Vector3, m: Material, teinte: Color = Color.WHITE) -> void:
	var centre: Vector3 = (coins[0] + coins[2]) * 0.5
	var p := _paquet(m, centre)
	var st: SurfaceTool = p["st"]
	var n0: int = p["n"]
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for k in 4:
		st.set_color(teinte)
		st.set_normal(normale)
		st.set_uv(uvs[k])
		st.add_vertex(coins[k])
	st.add_index(n0); st.add_index(n0 + 1); st.add_index(n0 + 2)
	st.add_index(n0); st.add_index(n0 + 2); st.add_index(n0 + 3)
	p["n"] = n0 + 4


## Touffe de feuillage autour de "centre" : "nb" cartes de taille "s" réparties dans un ellipsoïde de rayons r.
## Chaque carte est éclairée comme la surface d'une boule, ce qui donne du volume.
static func feuillage(centre: Vector3, r: Vector3, nb: int, s: float, m: Material, rng: RandomNumberGenerator) -> void:
	for k in nb:
		var dir := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.6, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		var p := centre + Vector3(dir.x * r.x, dir.y * r.y, dir.z * r.z) * rng.randf_range(0.55, 1.0)
		var n := (dir + Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.3, 0.7), rng.randf_range(-0.7, 0.7))).normalized()
		var u := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
		var v := u.cross(n).normalized()
		if v.y < 0.0:
			v = -v
			u = -u
		var t := s * rng.randf_range(0.8, 1.2)
		var eclairage := (dir + Vector3.UP * 0.35).normalized()
		var g := rng.randf_range(0.85, 1.12)
		carte([p - u * t - v * t, p + u * t - v * t, p + u * t + v * t, p - u * t + v * t], eclairage, m, Color(g, g, g * rng.randf_range(0.9, 1.0)))
