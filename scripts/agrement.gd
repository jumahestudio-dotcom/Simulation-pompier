## Deuxième passe d'agrément de la ville : bas-côtés et ronds-points de la rocade,
## panneaux directionnels, berges du Cher (roseaux, saules), haies et arbres des parkings,
## lierre sur les murs de jardins. Tout ce qui est aléatoire passe par Details.rv(),
## pour que les bâtiments ne changent pas de place.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")
const Lot = preload("res://scripts/lot.gd")
const Details = preload("res://scripts/details.gd")
const Verdure = preload("res://scripts/verdure.gd")

const X_ROCADE := -420.0
const RONDS_POINTS: Array = [0.0, -300.0, 240.0]


static func construire(racine: Node3D) -> void:
	var rv := Details.rv()
	_rocade(racine, rv)
	_berges(rv)
	_parkings(rv)


static func _rocade(racine: Node3D, rv: RandomNumberGenerator) -> void:
	# Bas-côtés en herbe haute, entre la glissière et l'écran d'arbres
	for seg in [[-620.0, -330.0], [-270.0, -32.0], [32.0, 150.0], [215.0, 210.0], [270.0, 620.0]]:
		var a: float = seg[0]
		var b: float = seg[1]
		if b <= a:
			continue
		for cote in [-1.0, 1.0]:
			var x1: float = X_ROCADE + cote * 12.0
			var x2: float = X_ROCADE + cote * 17.0
			Verdure.pelouse(Rect2(minf(x1, x2), a, 5.0, b - a), 0.45, 0.04, 0.0, 1.4)
	# Ronds-points fleuris : couronne d'arbustes, graminées, massif central
	var fleurs: Array = [Color(0.85, 0.45, 0.75), Color(0.95, 0.8, 0.35), Color(0.6, 0.5, 0.9), Color(0.95, 0.55, 0.4)]
	for zr in RONDS_POINTS:
		var c := Vector3(X_ROCADE, 0.5, zr)
		for k in 22:
			var ang := k * TAU / 22.0
			Details.arbuste(c + Vector3(cos(ang) * 10.8, 0, sin(ang) * 10.8), 0.9, rv, fleurs[k % 4] if k % 2 == 0 else Color(0, 0, 0, 0))
		for k in 8:
			var ang := k * TAU / 8.0 + 0.3
			Details.arbuste(c + Vector3(cos(ang) * 6.5, 0, sin(ang) * 6.5), 1.5, rv)
		Verdure.pelouse(Rect2(c.x - 9.0, c.z - 9.0, 18.0, 18.0), 0.9, 0.2, 0.5, 1.1)
	# Panneaux directionnels avant chaque rond-point
	_direction(racine, Vector3(X_ROCADE + 13.5, 0, 45.0), 0.0, ["Centre ancien ←", "Tours ↑", "Rive sud ↑"], false)
	_direction(racine, Vector3(X_ROCADE - 13.5, 0, -45.0), PI, ["Centre ancien →", "Les Tilleuls ↑", "Caserne des pompiers →"], false)
	_direction(racine, Vector3(X_ROCADE - 13.5, 0, -345.0), PI, ["Les Tilleuls →", "Bois des Hâtes ↑"], false)
	_direction(racine, Vector3(X_ROCADE + 13.5, 0, 285.0), 0.0, ["Rive sud ←", "Hôpital ←", "Centre ancien ↑"], false)
	_direction(racine, Vector3(X_ROCADE - 13.5, 0, 195.0), PI, ["Joué-lès-Tours centre →", "Hôpital →"], true)


## Panneau directionnel sur deux poteaux : blanc (local) ou bleu (grand itinéraire).
## angle : 0 si on lit le panneau depuis +z (en roulant vers le nord, côté est), PI dans l'autre sens.
static func _direction(racine: Node3D, pos: Vector3, angle: float, lignes: Array, bleu: bool) -> void:
	var b := Basis(Vector3.UP, angle)
	var gris := Lot.couleur(Color(0.6, 0.62, 0.64))
	var h := 0.45 * lignes.size() + 0.2
	for dx in [-1.4, 1.4]:
		Lot.cylindre(0.06, 2.2 + h, pos + b * Vector3(dx, 0, 0) + Vector3(0, (2.2 + h) * 0.5, 0), gris)
	var fond := Color(0.1, 0.25, 0.6) if bleu else Color(0.96, 0.96, 0.94)
	var c := pos + Vector3(0, 2.2 + h * 0.5, 0)
	Lot.boite(Vector3(3.4, h, 0.05), c - b * Vector3(0, 0, 0.01), Lot.couleur(Color(0.5, 0.52, 0.54)), b)
	Lot.boite(Vector3(3.3, h - 0.08, 0.06), c + b * Vector3(0, 0, 0.005), Lot.couleur(fond), b)
	for i in lignes.size():
		var y := c.y + h * 0.5 - 0.32 - i * 0.45
		var t := Geo.texte(racine, lignes[i], Vector3(c.x, y, c.z) + b * Vector3(0, 0, 0.045), 30, Color.WHITE if bleu else Color(0.05, 0.05, 0.05), false)
		t.outline_size = 0
		t.rotation.y = angle
		t.pixel_size = 0.008


## Berges du Cher : touffes de roseaux au pied des quais, saules pleureurs sur les promenades.
static func _berges(rv: RandomNumberGenerator) -> void:
	var x := -880.0
	while x < 980.0:
		if absf(x - 100.0) > 14.0 and absf(x + 420.0) > 20.0 and rv.randf() < 0.55:
			var l := rv.randf_range(6.0, 22.0)
			Verdure.pelouse(Rect2(x, 160.2, l, 1.6), 4.0, 0.0, 0.07, 3.6)
			if rv.randf() < 0.6:
				Verdure.pelouse(Rect2(x + rv.randf_range(-8.0, 8.0), 198.2, l * 0.8, 1.6), 4.0, 0.0, 0.07, 3.6)
		x += rv.randf_range(15.0, 40.0)
	for k in 14:
		var px := rv.randf_range(-680.0, 860.0)
		if absf(px - 100.0) < 20.0 or absf(px + 420.0) < 25.0:
			continue
		saule(Vector3(px, 0, 155.5 if k % 2 == 0 else 204.5), rv.randf_range(0.9, 1.2), rv)


## Saule pleureur : tronc penché, houppier arrondi et longs rameaux qui retombent.
static func saule(pos: Vector3, taille: float, rv: RandomNumberGenerator) -> void:
	var ecorce := Lot.couleur(Color(0.38, 0.33, 0.27))
	var h := 3.2 * taille
	Lot.cylindre(0.28 * taille, h, pos + Vector3(0, h * 0.5, 0), ecorce, Basis(Vector3.FORWARD, rv.randf_range(-0.12, 0.12)))
	var cime := pos + Vector3(0, h + 1.6 * taille, 0)
	var vert := Color(0.55, 0.66, 0.32)
	Lot.sphere(2.2 * taille, cime, Tex.mat_feuillage(vert.darkened(0.35)), 0.7)
	var m := Tex.mat_rameau(vert)
	Lot.feuillage(cime, Vector3(3.0, 1.4, 3.0) * taille, 40, 0.7 * taille, m, rv)
	# Rameaux retombants : cartes verticales tout autour, jusqu'à 1 m du sol
	var R := 3.4 * taille
	for k in 46:
		var ang := rv.randf() * TAU
		var r := R * rv.randf_range(0.65, 1.0)
		var haut := cime + Vector3(cos(ang) * r, rv.randf_range(-0.3, 0.6), sin(ang) * r)
		var bas := Vector3(haut.x, rv.randf_range(1.0, 2.2), haut.z)
		var dirx := Vector3(-sin(ang), 0, cos(ang)) * rv.randf_range(0.35, 0.55)
		var n := Vector3(cos(ang), 0.2, sin(ang)).normalized()
		Lot.carte([bas - dirx, bas + dirx, haut + dirx, haut - dirx], n, m)


## Parkings des Tilleuls : haie basse sur les longs côtés, un arbre toutes les 5 places.
static func _parkings(rv: RandomNumberGenerator) -> void:
	for r in [Rect2(-175, -188, 100, 16), Rect2(-312, -180, 40, 16), Rect2(-255, -330, 40, 16), Rect2(-312, -255, 44, 14), Rect2(-175, -310, 50, 14), Rect2(-120, -246, 50, 16)]:
		var rr: Rect2 = r
		var c := rr.get_center()
		Details.haie(Vector3(c.x, 0.45, rr.position.y - 0.8), rr.size.x, 0.9, 0.8, true, rv, Color(0.32, 0.46, 0.24))
		var x := rr.position.x + 6.0
		while x < rr.end.x - 3.0:
			Details.arbre(Vector3(x, 0, rr.end.y + 1.6), rv.randf_range(0.8, 1.0), rv)
			x += 12.5
