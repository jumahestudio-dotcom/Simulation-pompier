## Ce qui garnit la carte : forêts autour de la ville, aires de jeux, square, jardins familiaux,
## stade, courts de tennis, cimetière, clôtures des prés avec des vaches, conteneurs à déchets.
## Tout passe par lot.gd (gros maillages regroupés) pour rester léger.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")
const Lot = preload("res://scripts/lot.gd")
const Modeles = preload("res://scripts/modeles3d.gd")
const Verdure = preload("res://scripts/verdure.gd")
const Details = preload("res://scripts/details.gd")

const BOIS := Color(0.48, 0.34, 0.2)
const GRILLAGE := Color(0.22, 0.35, 0.25)


static func construire(racine: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2037
	# Forêts qui ferment l'horizon
	_foret(racine, rng, Rect2(-395, -690, 1060, 225), "Bois des Hâtes", Vector3(120, 0, -462))
	_foret(racine, rng, Rect2(690, -690, 300, 830), "Bois de la Douée", Vector3(686, 0, -200))
	_foret(racine, rng, Rect2(-395, 485, 1385, 210), "Bois de Bréchenay", Vector3(100, 0, 480))
	_foret(racine, rng, Rect2(690, 215, 300, 270), "", Vector3.ZERO)
	# Bordure ouest de la carte : bois continu (sauf sur le Cher) et angles nord-ouest et sud-ouest
	var rng_bord := RandomNumberGenerator.new()
	rng_bord.seed = 4242
	for r in [Rect2(-920, -700, 130, 840), Rect2(-920, 222, 130, 478), Rect2(-790, -700, 395, 100), Rect2(-790, 595, 395, 105)]:
		_foret(racine, rng_bord, r, "", Vector3.ZERO)
	# Ripisylve : arbres au bord du Cher hors de la ville
	for r in [Rect2(-880, 138, 440, 16), Rect2(-880, 206, 440, 16), Rect2(690, 138, 300, 16), Rect2(690, 206, 300, 16)]:
		_bosquet(rng, r, 90.0)
	# Rive sud : square, jardins familiaux, tennis, cimetière, stade
	_square(racine, rng, Rect2(-135, 272, 120, 105))
	_jardins_familiaux(racine, rng, Rect2(30, 318, 62, 60))
	_tennis(racine, Vector3(415, 0, 305))
	_cimetiere(racine, rng, Rect2(375, 345, 85, 110))
	_stade(racine, rng, Vector3(565, 0, 370))
	# Aires de jeux
	_aire_de_jeux(racine, rng, Vector3(-222, 0, -226), PI * 0.5)
	_aire_de_jeux(racine, rng, Vector3(-345, 0, 285), PI * 0.5)
	_aire_de_jeux(racine, rng, Vector3(-60, 0, 355), 0.0)
	_aire_de_jeux(racine, rng, Vector3(300, 0, -452), PI)
	# Grands ensembles : conteneurs, bancs, haies et arbres supplémentaires
	for p in [Vector3(-192, 0, -183), Vector3(-322, 0, -172), Vector3(-262, 0, -322), Vector3(-200, 0, -392)]:
		_conteneurs(p)
	for k in 30:
		var pa := Vector3(rng.randf_range(-320, -70), 0, rng.randf_range(-440, -165))
		if _libre_ge(pa):
			Lot.arbre_feuillu(pa, rng.randf_range(0.8, 1.2), _feuillage(rng), Lot.couleur(Color(0.42, 0.33, 0.24)))
	# Plus de verdure aux Tilleuls : arbres feuillus et massifs d'arbustes entre les immeubles
	var rv := Details.rv()
	for k in 70:
		var pa := Vector3(rv.randf_range(-320, -70), 0, rv.randf_range(-440, -165))
		if _libre_ge(pa):
			if k % 3 == 0:
				for i in rv.randi_range(2, 4):
					Details.arbuste(pa + Vector3(rv.randf_range(-2.0, 2.0), 0, rv.randf_range(-2.0, 2.0)), rv.randf_range(1.0, 2.2), rv)
			else:
				Details.arbre(pa, rv.randf_range(0.8, 1.25), rv)
	# Prés clôturés avec des vaches, à l'ouest de la rocade, et bosquets dans la campagne
	_pres(racine, rng)
	var rng_ferme := RandomNumberGenerator.new()
	rng_ferme.seed = 77
	_ferme(racine, rng_ferme)
	for k in 10:
		var bc := Vector2(rng.randf_range(-860, -480), rng.randf_range(-620, 620))
		if absf(bc.y - 180.0) > 50.0:
			_bosquet(rng, Rect2(bc.x, bc.y, rng.randf_range(20, 45), rng.randf_range(20, 45)), 60.0)
	# Rive sud : petites résidences (R+3) avec parkings, entre l'hôpital et les pavillons
	for q in [Vector3(130, 0, 310), Vector3(130, 0, 355), Vector3(205, 0, 310), Vector3(205, 0, 355)]:
		_residence(racine, rng, q)
	# Grillage le long de la rocade
	var za := -620.0
	while za < 620.0:
		var ok := not (za > 145.0 and za < 215.0)
		for zr in [-300.0, 0.0, 240.0]:
			if absf(za - zr) < 34.0:
				ok = false
		if ok:
			for cote in [-1.0, 1.0]:
				Lot.boite_c(Vector3(0.05, 1.6, 10.0), Vector3(-420 + cote * 15.0, 0.8, za + 5.0), GRILLAGE)
				Lot.cylindre(0.05, 1.8, Vector3(-420 + cote * 15.0, 0.9, za), Lot.couleur(GRILLAGE))
		za += 10.0


static func _feuillage(rng: RandomNumberGenerator) -> Material:
	var teintes: Array = [Color(0.2, 0.33, 0.14), Color(0.26, 0.4, 0.17), Color(0.32, 0.45, 0.2), Color(0.22, 0.36, 0.2), Color(0.38, 0.47, 0.22)]
	var t: Color = teintes[rng.randi() % teintes.size()]
	return Tex.mat_feuillage(t.lightened(0.25))


static func _foret(racine: Node3D, rng: RandomNumberGenerator, r: Rect2, nom: String, panneau: Vector3) -> void:
	# Sous-bois plus sombre que la prairie
	var c := r.get_center()
	Lot.boite(Vector3(r.size.x, 0.04, r.size.y), Vector3(c.x, 0.05, c.y), Tex.plaque("herbe", Tex.herbe(), 4.0, 4.0, Color(0.55, 0.62, 0.42)))
	var tronc := Lot.couleur(Color(0.36, 0.27, 0.2))
	var sapin: Array = [Lot.couleur(Color(0.1, 0.24, 0.14)), Lot.couleur(Color(0.13, 0.28, 0.16))]
	var nb := int(r.size.x * r.size.y / 170.0)
	for k in nb:
		var p := Vector3(rng.randf_range(r.position.x + 2.0, r.end.x - 2.0), 0, rng.randf_range(r.position.y + 2.0, r.end.y - 2.0))
		var t := rng.randf_range(0.8, 1.5)
		if rng.randf() < 0.35:
			Lot.arbre_conifere(p, t, sapin[rng.randi() % 2], tronc)
		else:
			Lot.arbre_feuillu(p, t, _feuillage(rng), tronc)
		if rng.randf() < 0.15:
			Lot.sphere(rng.randf_range(0.6, 1.2), p + Vector3(rng.randf_range(-3, 3), 0.3, rng.randf_range(-3, 3)), _feuillage(rng), 0.6)
	# Lisière : clôture de rondins et chemin forestier
	if nom != "":
		var est := panneau.x > 650.0
		var sud := panneau.z > c.y
		if est:
			var z := r.position.y
			while z < r.end.y:
				Lot.boite_c(Vector3(0.18, 1.0, 0.18), Vector3(r.position.x - 1.5, 0.5, z), BOIS)
				z += 3.0
			Lot.boite_c(Vector3(r.size.x, 0.06, 4.0), Vector3(c.x, 0.07, panneau.z + 2.0), Color(0.55, 0.47, 0.35))
		else:
			var x := r.position.x
			while x < r.end.x:
				Lot.boite_c(Vector3(0.18, 1.0, 0.18), Vector3(x, 0.5, r.end.y + 1.5 if sud else r.position.y - 1.5), BOIS)
				x += 3.0
			Lot.boite_c(Vector3(4.0, 0.06, r.size.y), Vector3(panneau.x + 2.0, 0.07, c.y), Color(0.55, 0.47, 0.35))
		# Panneau de bois à l'entrée du chemin
		Lot.boite_c(Vector3(0.15, 2.2, 0.15), panneau + Vector3(-1.0, 1.1, 0), BOIS)
		Lot.boite_c(Vector3(0.15, 2.2, 0.15), panneau + Vector3(1.0, 1.1, 0), BOIS)
		Lot.boite_c(Vector3(2.6, 0.7, 0.1), panneau + Vector3(0, 1.9, 0), Color(0.55, 0.4, 0.25))
		var t2 := Geo.texte(racine, nom, panneau + Vector3(0, 1.9, 0.07 if sud else -0.07), 30, Color(0.98, 0.95, 0.85), false)
		t2.outline_size = 0
		if not sud:
			t2.rotation.y = PI
		if est:
			t2.rotation.y = -PI * 0.5
			t2.position = panneau + Vector3(-0.07, 1.9, 0)


static func _bosquet(rng: RandomNumberGenerator, r: Rect2, densite: float) -> void:
	var tronc := Lot.couleur(Color(0.36, 0.27, 0.2))
	for k in int(r.size.x * r.size.y / densite):
		var p := Vector3(rng.randf_range(r.position.x, r.end.x), 0, rng.randf_range(r.position.y, r.end.y))
		Lot.arbre_feuillu(p, rng.randf_range(0.8, 1.3), _feuillage(rng), tronc)


static func _libre_ge(p: Vector3) -> bool:
	var occupes: Array = [Rect2(-302, -217, 24, 24), Rect2(-246, -266, 22, 22), Rect2(-241, -406, 22, 22), Rect2(-172, -377, 24, 24), Rect2(-101, -346, 22, 22),
		Rect2(-168, -215, 86, 20), Rect2(-285, -402, 22, 76), Rect2(-182, -284, 44, 28), Rect2(-132, -420, 44, 30), Rect2(-230, -236, 16, 20), Rect2(-178, -190, 106, 20)]
	for r in occupes:
		var rr: Rect2 = r
		if rr.grow(3.0).has_point(Vector2(p.x, p.z)):
			return false
	return true


static func _conteneurs(p: Vector3) -> void:
	var couleurs: Array = [Color(0.2, 0.45, 0.25), Color(0.85, 0.75, 0.1), Color(0.2, 0.35, 0.6), Color(0.35, 0.35, 0.37)]
	Lot.boite_c(Vector3(7.5, 0.1, 2.6), p + Vector3(0, 0.05, 0), Color(0.6, 0.6, 0.6))
	for k in 4:
		var q := p + Vector3(-2.7 + k * 1.8, 0, 0)
		Lot.boite_c(Vector3(1.4, 1.3, 1.2), q + Vector3(0, 0.75, 0), couleurs[k])
		Lot.boite_c(Vector3(1.45, 0.08, 1.25), q + Vector3(0, 1.43, 0), Color(couleurs[k]).darkened(0.25))
	# Muret d'enclos
	Lot.boite_c(Vector3(7.8, 1.5, 0.2), p + Vector3(0, 0.75, -1.4), Color(0.75, 0.73, 0.7))


## Aire de jeux : sol souple, toboggan, balançoires, jeux à ressort, bac à sable, clôture.
static func _aire_de_jeux(racine: Node3D, rng: RandomNumberGenerator, c: Vector3, angle: float) -> void:
	var b := Basis(Vector3.UP, angle)
	var P := func(x: float, y: float, z: float) -> Vector3: return c + b * Vector3(x, y, z)
	Lot.boite(Vector3(18, 0.08, 13), P.call(0, 0.06, 0), Lot.couleur(Color(0.25, 0.55, 0.45)), b)
	Lot.boite(Vector3(7, 0.09, 5), P.call(-4.5, 0.07, -3.0), Lot.couleur(Color(0.85, 0.45, 0.2)), b)
	# Clôture basse en bois avec un portillon
	for cote in [-1.0, 1.0]:
		Lot.boite(Vector3(18.4, 0.08, 0.06), P.call(0, 0.9, cote * 6.7), Lot.couleur(BOIS), b)
		Lot.boite(Vector3(0.06, 0.08, 13.4), P.call(cote * 9.2, 0.9, 0), Lot.couleur(BOIS), b)
		Lot.boite(Vector3(18.4, 0.08, 0.06), P.call(0, 0.4, cote * 6.7), Lot.couleur(BOIS), b)
		Lot.boite(Vector3(0.06, 0.08, 13.4), P.call(cote * 9.2, 0.4, 0), Lot.couleur(BOIS), b)
	for k in 13:
		for cote in [-1.0, 1.0]:
			if not (cote > 0.0 and k == 6):
				Lot.boite(Vector3(0.12, 1.1, 0.12), P.call(-9.2 + k * 1.533, 0.55, cote * 6.7), Lot.couleur(BOIS), b)
	# Toboggan : tour avec toit, échelle et glissière
	var tour: Vector3 = P.call(-4.5, 0, -3.0)
	for dx in [-0.7, 0.7]:
		for dz in [-0.7, 0.7]:
			Lot.boite(Vector3(0.12, 2.8, 0.12), tour + b * Vector3(dx, 1.4, dz), Lot.couleur(Color(0.95, 0.75, 0.15)), b)
	Lot.boite(Vector3(1.6, 0.1, 1.6), tour + b * Vector3(0, 1.4, 0), Lot.couleur(BOIS), b)
	Lot.toit(1.9, 0.8, 1.9, tour + b * Vector3(0, 2.8, 0), Lot.couleur(Color(0.85, 0.2, 0.15)), b)
	var glisse := b * Basis(Vector3.RIGHT, -0.62)
	Lot.boite(Vector3(0.6, 0.06, 2.6), tour + b * Vector3(0, 0.75, 1.85), Lot.couleur(Color(0.2, 0.5, 0.85)), glisse)
	for dx2 in [-0.32, 0.32]:
		Lot.boite(Vector3(0.05, 0.2, 2.6), tour + b * Vector3(dx2, 0.85, 1.85), Lot.couleur(Color(0.2, 0.5, 0.85)), glisse)
	var echelle := b * Basis(Vector3.RIGHT, 0.35)
	for dx3 in [-0.3, 0.3]:
		Lot.boite(Vector3(0.06, 1.6, 0.06), tour + b * Vector3(dx3, 0.75, -1.05), Lot.couleur(BOIS), echelle)
	for k in 5:
		Lot.boite(Vector3(0.6, 0.05, 0.05), tour + b * Vector3(0, 0.2 + k * 0.28, -1.25 + k * 0.1), Lot.couleur(BOIS), b)
	# Balançoires
	var bal: Vector3 = P.call(4.0, 0, -3.0)
	for dx in [-2.0, 2.0]:
		for dz in [-0.8, 0.8]:
			var pied := b * Basis(Vector3.RIGHT, -dz * 0.3)
			Lot.boite(Vector3(0.1, 2.5, 0.1), bal + b * Vector3(dx, 1.2, dz * 0.5), Lot.couleur(Color(0.2, 0.45, 0.75)), pied)
	Lot.boite(Vector3(4.2, 0.1, 0.1), bal + b * Vector3(0, 2.4, 0), Lot.couleur(Color(0.2, 0.45, 0.75)), b)
	for dx in [-1.0, 1.0]:
		for dc in [-0.25, 0.25]:
			Lot.boite(Vector3(0.02, 1.85, 0.02), bal + b * Vector3(dx + dc, 1.45, 0), Lot.couleur(Color(0.4, 0.4, 0.4)), b)
		Lot.boite(Vector3(0.6, 0.06, 0.25), bal + b * Vector3(dx, 0.5, 0), Lot.couleur(Color(0.85, 0.2, 0.15)), b)
	# Jeux à ressort et tourniquet
	var couleurs: Array = [Color(0.95, 0.75, 0.1), Color(0.3, 0.7, 0.3), Color(0.85, 0.3, 0.5)]
	for k in 3:
		var q: Vector3 = P.call(-6.0 + k * 3.0, 0, 3.2)
		Lot.cylindre(0.08, 0.5, q + Vector3(0, 0.25, 0), Lot.couleur(Color(0.5, 0.5, 0.5)))
		Lot.boite(Vector3(0.35, 0.5, 0.9), q + b * Vector3(0, 0.75, 0), Lot.couleur(couleurs[k]), b)
		Lot.boite(Vector3(0.3, 0.35, 0.3), q + b * Vector3(0, 1.1, -0.4), Lot.couleur(couleurs[k]), b)
	Lot.cylindre(1.2, 0.12, P.call(4.5, 0.4, 3.2), Lot.couleur(Color(0.85, 0.2, 0.15)))
	Lot.cylindre(0.05, 0.9, P.call(4.5, 0.85, 3.2), Lot.couleur(Color(0.6, 0.6, 0.6)))
	# Bac à sable et bancs
	Lot.boite(Vector3(3.0, 0.3, 3.0), P.call(7.0, 0.15, 3.2), Lot.couleur(BOIS), b)
	Lot.boite(Vector3(2.7, 0.32, 2.7), P.call(7.0, 0.16, 3.2), Lot.couleur(Color(0.9, 0.82, 0.6)), b)
	for k in 2:
		var bc: Vector3 = P.call(-7.5 + k * 15.0, 0, 5.3)
		Lot.boite(Vector3(1.8, 0.06, 0.45), bc + b * Vector3(0, 0.45, 0), Lot.couleur(BOIS), b)
		Lot.boite(Vector3(1.8, 0.4, 0.06), bc + b * Vector3(0, 0.7, 0.22), Lot.couleur(BOIS), b)
		Lot.boite(Vector3(1.6, 0.42, 0.4), bc + b * Vector3(0, 0.21, 0), Lot.couleur(Color(0.3, 0.3, 0.3)), b)


static func _square(racine: Node3D, rng: RandomNumberGenerator, r: Rect2) -> void:
	var c := r.get_center()
	var ce := Vector3(c.x, 0, c.y)
	# Grille du square avec deux entrées
	for cote in [-1.0, 1.0]:
		Lot.boite_c(Vector3(r.size.x, 1.3, 0.06), ce + Vector3(0, 0.65, cote * r.size.y * 0.5), Color(0.15, 0.25, 0.18))
		Lot.boite_c(Vector3(0.06, 1.3, r.size.y), ce + Vector3(cote * r.size.x * 0.5, 0.65, 0), Color(0.15, 0.25, 0.18))
	# Allées en stabilisé, en croix, et rond central avec fontaine
	Lot.boite_c(Vector3(r.size.x, 0.05, 4.0), ce + Vector3(0, 0.07, 0), Color(0.82, 0.76, 0.62))
	Lot.boite_c(Vector3(4.0, 0.05, r.size.y), ce + Vector3(0, 0.07, 0), Color(0.82, 0.76, 0.62))
	Lot.cylindre(9.0, 0.05, ce + Vector3(0, 0.072, 0), Lot.couleur(Color(0.82, 0.76, 0.62)))
	Lot.cylindre(4.0, 0.6, ce + Vector3(0, 0.3, 0), Lot.couleur(Color(0.85, 0.82, 0.75)))
	Lot.cylindre(3.7, 0.1, ce + Vector3(0, 0.56, 0), Lot.couleur(Color(0.3, 0.5, 0.65), 0.1))
	Lot.cylindre(0.4, 2.0, ce + Vector3(0, 1.0, 0), Lot.couleur(Color(0.85, 0.82, 0.75)))
	Lot.cylindre(1.3, 0.2, ce + Vector3(0, 2.0, 0), Lot.couleur(Color(0.85, 0.82, 0.75)))
	# Kiosque à musique
	var k0 := ce + Vector3(-35, 0, -28)
	Lot.cylindre(5.0, 0.8, k0 + Vector3(0, 0.4, 0), Lot.couleur(Color(0.85, 0.82, 0.75)))
	for i in 8:
		var a := i * TAU / 8.0
		Lot.cylindre(0.12, 3.2, k0 + Vector3(cos(a) * 4.5, 2.4, sin(a) * 4.5), Lot.couleur(Color(0.2, 0.35, 0.3)))
	Lot.cone(5.6, 2.0, k0 + Vector3(0, 5.0, 0), Lot.couleur(Color(0.3, 0.45, 0.42)))
	# Massifs de fleurs
	var fleurs: Array = [Color(0.85, 0.15, 0.2), Color(0.95, 0.8, 0.1), Color(0.7, 0.3, 0.75), Color(0.95, 0.5, 0.15)]
	for q in [Vector3(18, 0, 18), Vector3(-18, 0, 18), Vector3(18, 0, -18), Vector3(-18, 0, -18)]:
		Lot.boite_c(Vector3(10, 0.3, 6), ce + q + Vector3(0, 0.15, 0), Color(0.35, 0.25, 0.18))
		for k in 12:
			Details.arbuste(ce + q + Vector3(-4.2 + (k % 6) * 1.7, 0.3, -1.4 + int(k / 6) * 2.8), 0.75, Details.rv(), fleurs[k % 4].lightened(0.25))
		# Massif végétal scanné au bout de chaque parterre
		Modeles.poser(racine, Modeles.PLANTES, ce + q + Vector3(0, 0.25, 0), rng.randf() * TAU, 0.45, "Plants*#%d" % (9 + rng.randi() % 6), false)
	# Bancs le long des allées et arbres
	for k in 8:
		var dx := -45.0 + k * 13.0
		if absf(dx) < 10.0:
			continue
		Lot.boite_c(Vector3(1.8, 0.06, 0.45), ce + Vector3(dx, 0.45, 2.6), BOIS)
		Lot.boite_c(Vector3(1.8, 0.4, 0.06), ce + Vector3(dx, 0.7, 2.85), BOIS)
	for k in 22:
		var p := ce + Vector3(rng.randf_range(-r.size.x * 0.45, r.size.x * 0.45), 0, rng.randf_range(-r.size.y * 0.45, r.size.y * 0.45))
		if absf(p.x - ce.x) > 5.0 and absf(p.z - ce.z) > 5.0 and p.distance_to(ce) > 12.0 and p.distance_to(k0) > 8.0:
			var arbre: String = "Tree 1" if k % 2 == 0 else "Tree 2"
			if k % 3 == 0 or Modeles.poser(racine, Modeles.ARBRE, p, rng.randf() * TAU, rng.randf_range(1.0, 1.4), arbre, false) == null:
				var tt := rng.randf_range(0.9, 1.3)
				_feuillage(rng)
				Details.arbre(p, tt, Details.rv())
	# Herbe haute et fleurs sur les pelouses (hors allées et bassin)
	Verdure.exclure(Rect2(c.x - r.size.x * 0.5, c.y - 2.5, r.size.x, 5.0))
	Verdure.exclure(Rect2(c.x - 2.5, c.y - r.size.y * 0.5, 5.0, r.size.y))
	Verdure.exclure(Rect2(c.x - 9.5, c.y - 9.5, 19.0, 19.0))
	Verdure.exclure(Rect2(k0.x - 5.5, k0.z - 5.5, 11.0, 11.0))
	Verdure.pelouse(r.grow(-1.0), 0.7, 0.12)
	var rv := Details.rv()
	for k in 14:
		var pa := ce + Vector3(rv.randf_range(-r.size.x * 0.47, r.size.x * 0.47), 0, rv.randf_range(-r.size.y * 0.47, r.size.y * 0.47))
		if absf(pa.x - ce.x) > 3.5 and absf(pa.z - ce.z) > 3.5 and pa.distance_to(ce) > 11.0:
			Details.arbuste(pa, rv.randf_range(1.0, 1.8), rv)
	var t := Geo.texte(racine, "Square de la Mairie", ce + Vector3(0, 2.4, r.size.y * 0.5 + 0.1), 40, Color(0.95, 0.95, 0.9), false)
	t.outline_size = 6


static func _jardins_familiaux(racine: Node3D, rng: RandomNumberGenerator, r: Rect2) -> void:
	var legumes: Array = [Color(0.3, 0.55, 0.2), Color(0.4, 0.6, 0.25), Color(0.25, 0.45, 0.2), Color(0.55, 0.65, 0.3)]
	var x := r.position.x
	while x < r.end.x - 8.0:
		var z := r.position.y
		while z < r.end.y - 8.0:
			var c := Vector3(x + 7.0, 0, z + 7.0)
			Lot.boite_c(Vector3(13, 0.06, 13), c + Vector3(0, 0.06, 0), Color(0.42, 0.32, 0.22))
			for k in 5:
				Lot.boite_c(Vector3(9, 0.35, 1.0), c + Vector3(-1.0, 0.2, -5.0 + k * 2.2), legumes[rng.randi() % legumes.size()])
			# Cabane, récupérateur d'eau, grillage
			Lot.boite_c(Vector3(2.2, 2.1, 2.0), c + Vector3(4.8, 1.05, -4.8), Color(0.45, 0.35, 0.25))
			Lot.toit(2.4, 0.5, 2.4, c + Vector3(4.8, 2.1, -4.8), Lot.couleur(Color(0.25, 0.3, 0.25)), Basis.IDENTITY)
			Lot.cylindre(0.45, 1.1, c + Vector3(4.8, 0.55, -2.8), Lot.couleur(Color(0.2, 0.4, 0.25)))
			for cote in [-1.0, 1.0]:
				Lot.boite_c(Vector3(14, 1.2, 0.04), c + Vector3(0, 0.6, cote * 7.0), GRILLAGE)
				Lot.boite_c(Vector3(0.04, 1.2, 14), c + Vector3(cote * 7.0, 0.6, 0), GRILLAGE)
			z += 15.0
		x += 15.0
	Geo.texte(racine, "Jardins familiaux", Vector3(r.get_center().x, 2.2, r.position.y - 0.5), 34, Color(0.95, 0.95, 0.9))


static func _tennis(racine: Node3D, c: Vector3) -> void:
	for k in 2:
		var q := c + Vector3(k * 20.0 - 10.0, 0, 0)
		Lot.boite_c(Vector3(18, 0.06, 36), q + Vector3(0, 0.06, 0), Color(0.72, 0.38, 0.25))
		Lot.boite_c(Vector3(11, 0.07, 24), q + Vector3(0, 0.065, 0), Color(0.2, 0.45, 0.55))
		for zz in [-12.0, 12.0, 0.0]:
			Lot.boite_c(Vector3(11, 0.02, 0.08), q + Vector3(0, 0.1, zz), Color(0.95, 0.95, 0.95))
		for xx in [-5.5, 5.5]:
			Lot.boite_c(Vector3(0.08, 0.02, 24), q + Vector3(xx, 0.1, 0), Color(0.95, 0.95, 0.95))
		Lot.boite_c(Vector3(12.5, 0.9, 0.03), q + Vector3(0, 0.55, 0), Color(0.15, 0.15, 0.15))
		for cote in [-1.0, 1.0]:
			Lot.boite_c(Vector3(18, 3.0, 0.04), q + Vector3(0, 1.5, cote * 18.0), GRILLAGE)
			Lot.boite_c(Vector3(0.04, 3.0, 36), q + Vector3(cote * 9.0, 1.5, 0), GRILLAGE)


static func _cimetiere(racine: Node3D, rng: RandomNumberGenerator, r: Rect2) -> void:
	var c := r.get_center()
	var ce := Vector3(c.x, 0, c.y)
	var mur := Color(0.86, 0.82, 0.72)
	for cote in [-1.0, 1.0]:
		Lot.boite_c(Vector3(r.size.x, 2.2, 0.4), ce + Vector3(0, 1.1, cote * r.size.y * 0.5), mur)
		if cote < 0.0:
			# Portail d'entrée côté ouest
			Lot.boite_c(Vector3(0.4, 2.2, r.size.y * 0.5 - 3.0), ce + Vector3(-r.size.x * 0.5, 1.1, -r.size.y * 0.25 - 1.5), mur)
			Lot.boite_c(Vector3(0.4, 2.2, r.size.y * 0.5 - 3.0), ce + Vector3(-r.size.x * 0.5, 1.1, r.size.y * 0.25 + 1.5), mur)
			Lot.boite_c(Vector3(0.1, 2.0, 6.0), ce + Vector3(-r.size.x * 0.5, 1.0, 0), Color(0.1, 0.1, 0.12))
		else:
			Lot.boite_c(Vector3(0.4, 2.2, r.size.y), ce + Vector3(r.size.x * 0.5, 1.1, 0), mur)
	Lot.boite_c(Vector3(r.size.x - 2, 0.05, 3.5), ce + Vector3(0, 0.07, 0), Color(0.78, 0.74, 0.65))
	# Rangées de tombes
	var gris: Array = [Color(0.55, 0.55, 0.56), Color(0.35, 0.35, 0.37), Color(0.7, 0.68, 0.62), Color(0.25, 0.25, 0.27)]
	var x := r.position.x + 5.0
	while x < r.end.x - 4.0:
		for z in range(int(r.position.y) + 5, int(r.end.y) - 4, 4):
			if absf(z - c.y) < 3.0:
				continue
			var g: Color = gris[rng.randi() % gris.size()]
			Lot.boite_c(Vector3(1.0, 0.35, 2.1), Vector3(x, 0.17, z), g)
			Lot.boite_c(Vector3(0.9, rng.randf_range(0.7, 1.1), 0.15), Vector3(x, 0.7, z - 1.0), g)
			if rng.randf() < 0.3:
				Lot.sphere(0.2, Vector3(x, 0.45, z + 0.3), Lot.couleur(Color(0.85, 0.3, 0.3)), 0.7)
		x += 3.0
	# Cyprès et chapelle
	for k in 8:
		Lot.cone(0.9, 7.0, Vector3(r.position.x + 3.0 + k * (r.size.x - 6.0) / 7.0, 3.5, c.y - 3.0), Lot.couleur(Color(0.12, 0.25, 0.15)))
	var ch := Vector3(r.end.x - 9.0, 0, c.y)
	Lot.boite(Vector3(7, 5, 6), ch + Vector3(0, 2.5, 0), Tex.plaque("tuffeau_uni", Tex.beton(), 3.0, 3.0, Color(0.95, 0.9, 0.78)))
	Lot.toit(6.4, 3.0, 7.4, ch + Vector3(0, 5.0, 0), Tex.mat_ardoise(), Basis(Vector3.UP, PI * 0.5))
	Lot.boite_c(Vector3(0.15, 1.4, 0.15), ch + Vector3(0, 8.3, 0), Color(0.3, 0.3, 0.3))
	Lot.boite_c(Vector3(0.15, 0.15, 0.8), ch + Vector3(0, 8.6, 0), Color(0.3, 0.3, 0.3))


static func _stade(racine: Node3D, rng: RandomNumberGenerator, c: Vector3) -> void:
	# Piste d'athlétisme, terrain de football, tribune, pylônes d'éclairage, clôture
	Lot.boite_c(Vector3(90, 0.05, 160), c + Vector3(0, 0.06, 0), Color(0.72, 0.32, 0.22))
	Lot.boite(Vector3(68, 0.06, 105), c + Vector3(0, 0.07, 0), Tex.plaque("herbe", Tex.herbe(), 3.0, 3.0, Color(0.6, 0.9, 0.5)))
	for k in 7:
		Lot.boite_c(Vector3(68, 0.02, 7.5), c + Vector3(0, 0.1, -52.5 + 3.75 + k * 15.0), Color(0.4, 0.62, 0.32))
	var blanc := Color(0.95, 0.95, 0.95)
	for zz in [-52.5, 52.5, 0.0]:
		Lot.boite_c(Vector3(68, 0.02, 0.15), c + Vector3(0, 0.11, zz), blanc)
	for xx in [-34.0, 34.0]:
		Lot.boite_c(Vector3(0.15, 0.02, 105), c + Vector3(xx, 0.11, 0), blanc)
	Lot.cylindre(9.15, 0.02, c + Vector3(0, 0.105, 0), Lot.couleur(blanc))
	Lot.cylindre(9.0, 0.025, c + Vector3(0, 0.108, 0), Tex.plaque("herbe", Tex.herbe(), 3.0, 3.0, Color(0.6, 0.9, 0.5)))
	for s in [-1.0, 1.0]:
		Lot.boite_c(Vector3(40.3, 0.02, 16.5), c + Vector3(0, 0.104, s * 44.25), blanc)
		Lot.boite_c(Vector3(40.0, 0.025, 16.2), c + Vector3(0, 0.107, s * 44.25), Color(0.45, 0.68, 0.35))
		# Buts
		var bz: float = s * 52.5
		for bx in [-3.66, 3.66]:
			Lot.boite_c(Vector3(0.12, 2.44, 0.12), c + Vector3(bx, 1.22, bz), blanc)
		Lot.boite_c(Vector3(7.44, 0.12, 0.12), c + Vector3(0, 2.44, bz), blanc)
		Lot.boite(Vector3(7.3, 2.4, 0.03), c + Vector3(0, 1.2, bz + s * 1.5), Lot.couleur(Color(0.95, 0.95, 0.95, 0.35)))
	# Tribune couverte à l'est
	for k in 8:
		Lot.boite_c(Vector3(1.0, 0.45 + k * 0.45, 50), c + Vector3(48.0 + k * 0.9, (0.45 + k * 0.45) * 0.5, 0), Color(0.6, 0.6, 0.62))
		for j in 25:
			Lot.boite_c(Vector3(0.45, 0.35, 0.45), c + Vector3(48.0 + k * 0.9, 0.62 + k * 0.45, -24.0 + j * 2.0), [Color(0.1, 0.3, 0.7), Color(0.85, 0.15, 0.15)][(k + j) % 2])
	Lot.boite_c(Vector3(10, 0.25, 52), c + Vector3(51.5, 7.5, 0), Color(0.75, 0.75, 0.78))
	for j in 5:
		Lot.boite_c(Vector3(0.3, 7.5, 0.3), c + Vector3(56.0, 3.75, -24.0 + j * 12.0), Color(0.6, 0.6, 0.62))
	# Pylônes d'éclairage
	for px in [-50.0, 50.0]:
		for pz in [-70.0, 70.0]:
			Lot.cylindre(0.35, 22.0, c + Vector3(px, 11.0, pz), Lot.couleur(Color(0.6, 0.6, 0.62)))
			Lot.boite(Vector3(4.0, 2.5, 0.5), c + Vector3(px, 22.5, pz), Lot.couleur(Color(1.0, 1.0, 0.95), 0.6), Basis(Vector3.UP, atan2(px, pz)))
	# Clôture et club-house
	for cote in [-1.0, 1.0]:
		Lot.boite_c(Vector3(115, 2.0, 0.05), c + Vector3(5, 1.0, cote * 85.0), GRILLAGE)
		Lot.boite_c(Vector3(0.05, 2.0, 170), c + Vector3(5 + cote * 57.5, 1.0, 0), GRILLAGE)
	Lot.boite(Vector3(20, 3.5, 9), c + Vector3(-75, 1.75, -70), Tex.plaque("crepi", Tex.crepi(), 3.0, 2.8, Color(0.95, 0.92, 0.85)))
	Lot.toit(9.6, 2.0, 20.6, c + Vector3(-75, 3.5, -70), Lot.couleur(Color(0.7, 0.35, 0.25)), Basis(Vector3.UP, PI * 0.5))
	var t := Geo.texte(racine, "STADE MUNICIPAL", c + Vector3(51.5, 8.6, 0), 120, Color(0.95, 0.95, 0.95), false)
	t.rotation.y = -PI * 0.5


static func _pres(racine: Node3D, rng: RandomNumberGenerator) -> void:
	# Quelques pâtures clôturées (piquets et fils) avec des vaches, près de la ferme
	for r in [Rect2(-760, -40, 110, 90), Rect2(-610, 260, 120, 100), Rect2(-780, -330, 100, 110)]:
		var rr: Rect2 = r
		var c := rr.get_center()
		Lot.boite(Vector3(rr.size.x, 0.04, rr.size.y), Vector3(c.x, 0.08, c.y), Tex.mat_herbe())
		Verdure.pelouse(rr, 0.3, 0.1, 0.1, 1.5)
		var x := rr.position.x
		while x <= rr.end.x:
			for zz in [rr.position.y, rr.end.y]:
				Lot.boite_c(Vector3(0.15, 1.3, 0.15), Vector3(x, 0.65, zz), BOIS)
			x += 4.0
		var z := rr.position.y
		while z <= rr.end.y:
			for xx in [rr.position.x, rr.end.x]:
				Lot.boite_c(Vector3(0.15, 1.3, 0.15), Vector3(xx, 0.65, z), BOIS)
			z += 4.0
		for h in [0.6, 1.1]:
			for zz in [rr.position.y, rr.end.y]:
				Lot.boite_c(Vector3(rr.size.x, 0.03, 0.03), Vector3(c.x, h, zz), Color(0.5, 0.5, 0.5))
			for xx in [rr.position.x, rr.end.x]:
				Lot.boite_c(Vector3(0.03, 0.03, rr.size.y), Vector3(xx, h, c.y), Color(0.5, 0.5, 0.5))
		# Abreuvoir
		Lot.boite_c(Vector3(3.0, 0.6, 0.8), Vector3(rr.position.x + 5.0, 0.3, c.y), Color(0.6, 0.6, 0.62))
		for k in 7:
			_vache(Vector3(rng.randf_range(rr.position.x + 5, rr.end.x - 5), 0, rng.randf_range(rr.position.y + 5, rr.end.y - 5)), rng.randf() * TAU, rng)


static func _vache(p: Vector3, angle: float, rng: RandomNumberGenerator) -> void:
	var b := Basis(Vector3.UP, angle)
	var robe: Color = [Color(0.95, 0.93, 0.88), Color(0.55, 0.35, 0.2), Color(0.85, 0.8, 0.7)][rng.randi() % 3]
	Lot.boite(Vector3(0.9, 0.85, 2.0), p + b * Vector3(0, 1.15, 0), Lot.couleur(robe), b)
	Lot.boite(Vector3(0.5, 0.5, 0.65), p + b * Vector3(0, 1.35, -1.25), Lot.couleur(robe), b * Basis(Vector3.RIGHT, 0.4))
	Lot.boite(Vector3(0.35, 0.25, 0.2), p + b * Vector3(0, 1.15, -1.6), Lot.couleur(Color(0.9, 0.7, 0.65)), b)
	for dx in [-0.3, 0.3]:
		for dz in [-0.75, 0.75]:
			Lot.boite(Vector3(0.18, 0.75, 0.18), p + b * Vector3(dx, 0.37, dz), Lot.couleur(robe.darkened(0.15)), b)
	if robe.r > 0.9:
		Lot.boite(Vector3(0.92, 0.5, 0.6), p + b * Vector3(0, 1.25, 0.3), Lot.couleur(Color(0.12, 0.1, 0.1)), b)


static func _residence(racine: Node3D, rng: RandomNumberGenerator, c: Vector3) -> void:
	var teinte: Color = [Color(0.96, 0.92, 0.84), Color(0.92, 0.9, 0.86), Color(0.95, 0.88, 0.78)][rng.randi() % 3]
	Geo.boite_mat(racine, Vector3(28, 12, 12), c + Vector3(0, 6, 0), Tex.plaque("hlm", Tex.facade_hlm(), 3.0, 3.0, teinte))
	Lot.toit(12.6, 3.0, 28.6, c + Vector3(0, 12, 0), Tex.plaque("tuiles", Tex.tuiles(), 2.0, 2.0), Basis(Vector3.UP, PI * 0.5))
	# Balcons sur la façade sud, hall vitré, parking et haie
	for k in 5:
		for e in range(1, 4):
			Lot.boite_c(Vector3(3.2, 0.15, 1.2), c + Vector3(-11.0 + k * 5.5, e * 3.0, 6.6), Color(0.85, 0.85, 0.83))
			Lot.boite(Vector3(3.2, 0.9, 0.05), c + Vector3(-11.0 + k * 5.5, e * 3.0 + 0.5, 7.2), Lot.couleur(Color(0.4, 0.5, 0.6, 0.5)))
	Lot.boite(Vector3(3.5, 2.6, 0.1), c + Vector3(0, 1.3, -6.05), Tex.vitre())
	Lot.boite_c(Vector3(30, 0.05, 9), c + Vector3(0, 0.06, -12), Color(0.3, 0.3, 0.32))
	for k in 11:
		Lot.boite_c(Vector3(0.1, 0.02, 4.5), c + Vector3(-13.75 + k * 2.75, 0.09, -13.5), Color(0.9, 0.9, 0.9))
	Lot.boite_c(Vector3(30, 1.4, 0.8), c + Vector3(0, 0.7, 11), Color(0.2, 0.34, 0.16))



## Dépendances de la ferme (maison et grange posées par quartiers.gd) : grand hangar à foin ouvert,
## plein de bottes de paille (feux de récolte), stabulation couverte et enclos avec les bêtes.
static func _ferme(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var acier := Color(0.35, 0.38, 0.4)
	var tole := Color(0.42, 0.48, 0.45)
	var paille := Color(0.86, 0.74, 0.42)
	# --- Hangar à foin : 36 m x 16 m, 8 m sous gouttière, toit à deux pans, ouvert sur les côtés
	var hc := Vector3(-582.0, 0, -100.0)
	var hl := 36.0
	var hp := 16.0
	var hh := 8.0
	var x := -hl * 0.5
	while x <= hl * 0.5 + 0.1:
		for sz in [-hp * 0.5, hp * 0.5]:
			Lot.boite_c(Vector3(0.3, hh, 0.3), hc + Vector3(x, hh * 0.5, sz), acier)
			var poteau := StaticBody3D.new()
			poteau.position = hc + Vector3(x, hh * 0.5, sz)
			racine.add_child(poteau)
			var cp := CollisionShape3D.new()
			var fp := BoxShape3D.new()
			fp.size = Vector3(0.3, hh, 0.3)
			cp.shape = fp
			poteau.add_child(cp)
		# Ferme de charpente métallique
		Lot.boite_c(Vector3(0.2, 0.4, hp), hc + Vector3(x, hh, 0), acier)
		x += 6.0
	var pente := atan2(2.5, hp * 0.5)
	for cote in [-1.0, 1.0]:
		var b := Basis(Vector3.RIGHT, cote * pente)
		Lot.boite_c(Vector3(hl + 1.0, 0.08, hp * 0.5 / cos(pente) + 0.8), hc + Vector3(0, hh + 1.25, cote * hp * 0.25), tole, b)
		# Bardage haut sur les longs pans, le bas reste ouvert
		Lot.boite_c(Vector3(hl, 2.0, 0.06), hc + Vector3(0, hh - 1.0, cote * hp * 0.5), tole)
	# Pignon fermé côté ouest
	Lot.boite_c(Vector3(0.06, hh - 2.0, hp), hc + Vector3(-hl * 0.5, (hh - 2.0) * 0.5 + 2.0, 0), tole)
	Lot.boite_c(Vector3(0.6, 0.02, hp - 1.0), hc + Vector3(0, 0.085, 0), Color(0.45, 0.42, 0.36))
	# Bottes carrées empilées sur 4 rangs dans la moitié ouest, bottes rondes dans la moitié est
	for i in 7:
		for j in 6:
			for k in 4:
				if k == 3 and (i + j) % 3 == 0:
					continue
				var p := hc + Vector3(-hl * 0.5 + 1.6 + i * 2.45, 0.5 + k * 0.92, -hp * 0.5 + 1.6 + j * 1.25)
				Lot.boite_c(Vector3(2.4, 0.9, 1.2), p, paille.darkened(rng.randf_range(0.0, 0.12)))
	var tas := StaticBody3D.new()
	tas.position = hc + Vector3(-hl * 0.5 + 9.0, 1.8, 0)
	racine.add_child(tas)
	var ct := CollisionShape3D.new()
	var ft := BoxShape3D.new()
	ft.size = Vector3(17.5, 3.6, 7.6)
	ct.shape = ft
	tas.add_child(ct)
	for i in 5:
		for j in 2:
			for k in 2:
				var pr := hc + Vector3(3.0 + i * 1.85 + k * 0.9, 0.85 + k * 1.45, -4.2 + j * 6.5)
				Lot.cylindre(0.8, 1.25, pr, Lot.couleur(paille.darkened(rng.randf_range(0.02, 0.15))), Basis(Vector3.BACK, PI * 0.5))
	var tas2 := StaticBody3D.new()
	tas2.position = hc + Vector3(7.5, 1.5, 0)
	racine.add_child(tas2)
	var ct2 := CollisionShape3D.new()
	var ft2 := BoxShape3D.new()
	ft2.size = Vector3(10.0, 3.0, 13.0)
	ct2.shape = ft2
	tas2.add_child(ct2)
	# Quelques bottes rondes stockées dehors, sous bâche
	for i in 4:
		var po := hc + Vector3(-12.0 + i * 1.7, 0.8, hp * 0.5 + 4.0)
		Lot.cylindre(0.8, 1.25, po, Lot.couleur(Color(0.12, 0.12, 0.12)), Basis(Vector3.BACK, PI * 0.5))
	# Tracteur garé devant le hangar
	_tracteur(hc + Vector3(14.0, 0, hp * 0.5 + 5.0), PI * 0.5)
	# --- Stabulation couverte et enclos des bêtes, au sud de la grange
	var sc := Vector3(-640.0, 0, -77.0)
	Lot.boite_c(Vector3(26.0, 0.15, 12.0), sc + Vector3(0, 0.075, 0), Color(0.62, 0.6, 0.56))
	for sx in [-13.0, -6.5, 0.0, 6.5, 13.0]:
		for sz in [-6.0, 6.0]:
			Lot.boite_c(Vector3(0.25, 5.0 if sz < 0.0 else 4.0, 0.25), sc + Vector3(sx, (5.0 if sz < 0.0 else 4.0) * 0.5, sz), acier)
	Lot.boite_c(Vector3(27.0, 0.08, 13.2), sc + Vector3(0, 4.6, 0), tole, Basis(Vector3.RIGHT, atan2(1.0, 12.0)))
	Lot.boite_c(Vector3(26.0, 3.0, 0.15), sc + Vector3(0, 1.5, -6.0), Color(0.55, 0.3, 0.22))
	# Cornadis (barrière d'alimentation) et couloir de foin
	for i in 40:
		Lot.boite_c(Vector3(0.05, 1.2, 0.05), sc + Vector3(-12.5 + i * 0.64, 0.75, -3.6), Color(0.75, 0.6, 0.1))
	Lot.boite_c(Vector3(25.5, 0.06, 0.06), sc + Vector3(0, 1.35, -3.6), Color(0.75, 0.6, 0.1))
	Lot.boite_c(Vector3(24.0, 0.3, 1.2), sc + Vector3(0, 0.3, -4.6), paille)
	for i in 6:
		_vache(sc + Vector3(-10.0 + i * 4.0 + rng.randf_range(-0.6, 0.6), 0.15, -1.8), PI, rng)
	# Enclos en bois devant la stabulation
	var en := Rect2(-654.0, -71.0, 28.0, 20.0)
	var bois := Color(0.45, 0.33, 0.2)
	var px := en.position.x
	while px <= en.end.x + 0.01:
		Lot.boite_c(Vector3(0.18, 1.4, 0.18), Vector3(px, 0.7, en.end.y), bois)
		px += 2.8
	var pz := en.position.y
	while pz <= en.end.y + 0.01:
		for xx in [en.position.x, en.end.x]:
			Lot.boite_c(Vector3(0.18, 1.4, 0.18), Vector3(xx, 0.7, pz), bois)
		pz += 2.5
	for h in [0.5, 0.9, 1.3]:
		Lot.boite_c(Vector3(en.size.x - 4.0, 0.12, 0.06), Vector3(en.get_center().x + 2.0, h, en.end.y), bois)
		for xx in [en.position.x, en.end.x]:
			Lot.boite_c(Vector3(0.06, 0.12, en.size.y), Vector3(xx, h, en.get_center().y), bois)
	# Barrière métallique (portail) à l'angle ouest
	Lot.boite_c(Vector3(4.0, 1.1, 0.05), Vector3(en.position.x + 2.0, 0.7, en.end.y), Color(0.55, 0.58, 0.6))
	Lot.boite_c(Vector3(en.size.x, 0.02, en.size.y), Vector3(en.get_center().x, 0.08, en.get_center().y), Color(0.38, 0.45, 0.25))
	Lot.boite_c(Vector3(3.0, 0.6, 0.8), Vector3(en.end.x - 3.0, 0.3, en.get_center().y), Color(0.6, 0.6, 0.62))
	Lot.boite_c(Vector3(2.8, 0.05, 0.6), Vector3(en.end.x - 3.0, 0.58, en.get_center().y), Color(0.3, 0.42, 0.5))
	for k in 7:
		_vache(Vector3(rng.randf_range(en.position.x + 3, en.end.x - 3), 0.0, rng.randf_range(en.position.y + 3, en.end.y - 3)), rng.randf() * TAU, rng)
	# Râtelier à foin et botte ronde dans l'enclos
	Lot.cylindre(1.0, 1.0, Vector3(-640.0, 0.6, -60.0), Lot.couleur(paille))
	for i in 10:
		var a := i * TAU / 10.0
		Lot.boite_c(Vector3(0.05, 1.3, 0.05), Vector3(-640.0 + cos(a) * 1.15, 0.65, -60.0 + sin(a) * 1.15), Color(0.2, 0.35, 0.25))
	Lot.cylindre(1.15, 0.06, Vector3(-640.0, 1.3, -60.0), Lot.couleur(Color(0.2, 0.35, 0.25)))
	# Fumière
	Lot.boite_c(Vector3(8.0, 1.2, 0.3), Vector3(-662.0, 0.6, -84.0), Color(0.6, 0.6, 0.58))
	Lot.sphere(3.0, Vector3(-662.0, 0.0, -80.5), Lot.couleur(Color(0.3, 0.22, 0.14)), 0.45)


## Tracteur agricole simple (grandes roues arrière, cabine vitrée), avant vers "angle".
static func _tracteur(p: Vector3, angle: float) -> void:
	var b := Basis(Vector3.UP, angle)
	var vert := Color(0.2, 0.45, 0.2)
	var noir := Color(0.08, 0.08, 0.08)
	var axe := b * Basis(Vector3.BACK, PI * 0.5)
	Lot.boite_c(Vector3(1.1, 1.0, 2.6), p + b * Vector3(0, 1.3, -0.8), vert, b)
	Lot.boite_c(Vector3(1.6, 0.5, 1.8), p + b * Vector3(0, 1.3, 1.0), vert.darkened(0.2), b)
	Lot.boite_c(Vector3(1.5, 1.4, 1.6), p + b * Vector3(0, 2.3, 1.0), Color(0.25, 0.35, 0.4), b)
	Lot.boite_c(Vector3(1.6, 0.1, 1.7), p + b * Vector3(0, 3.05, 1.0), vert, b)
	Lot.cylindre(0.07, 1.0, p + b * Vector3(0.35, 2.3, -1.6), Lot.couleur(noir))
	for sx in [-0.95, 0.95]:
		Lot.cylindre(0.85, 0.55, p + b * Vector3(sx, 0.85, 1.2), Lot.couleur(noir), axe)
		Lot.cylindre(0.45, 0.56, p + b * Vector3(sx, 0.85, 1.2), Lot.couleur(Color(0.85, 0.7, 0.1)), axe)
		Lot.cylindre(0.5, 0.4, p + b * Vector3(sx * 0.85, 0.5, -1.6), Lot.couleur(noir), axe)
		Lot.cylindre(0.25, 0.41, p + b * Vector3(sx * 0.85, 0.5, -1.6), Lot.couleur(Color(0.85, 0.7, 0.1)), axe)
