## Construit le quartier : sol, rues, rivière, pont, immeubles en tuffeau aux toits d'ardoise,
## la caserne, la maison, l'immeuble du feu et le centre hospitalier.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Carte = preload("res://scripts/carte.gd")
const Tex = preload("res://scripts/textures.gd")
const Quartiers = preload("res://scripts/quartiers.gd")
const Details = preload("res://scripts/details.gd")
const Lot = preload("res://scripts/lot.gd")
const VoitureModele = preload("res://scripts/voiture_modele.gd")

const TUFFEAU: Array = [Color(0.95, 0.91, 0.80), Color(0.90, 0.86, 0.75), Color(1.0, 0.97, 0.88), Color(0.86, 0.81, 0.70)]
const ARDOISE := Color(0.27, 0.30, 0.35)
const ROUTE := Color(0.22, 0.22, 0.24)
const TROTTOIR := Color(0.55, 0.55, 0.55)

## Zones où l'on ne pose pas d'immeubles de remplissage (x, z, largeur, profondeur).
const RESERVES: Array = [
	Rect2(-292, -78, 84, 72),     # caserne
	Rect2(254, -104, 22, 26),     # maison du malaise
	Rect2(-44, -114, 26, 38),     # immeuble du feu
	Rect2(140, 6, 40, 20),        # trottoir de la chute
]


static func construire(racine: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 37  # toujours la même ville
	# Sol (herbe partout, trottoirs pavés dans le centre)
	Geo.boite_mat(racine, Vector3(1800, 1, 1400), Vector3(100, -0.5, 0), Tex.mat_herbe())
	Geo.boite_mat(racine, Vector3(660, 0.04, 320), Vector3(0, 0.02, -2), Tex.mat_paves(), false)
	# Toutes les rues, tracées à partir du plan (carte.gd)
	_routes(racine)
	for x in [-200.0, -50.0, 100.0, 250.0]:
		# Passages piétons sur le boulevard
		for k in 6:
			Geo.boite(racine, Vector3(0.5, 0.02, 3.0), Vector3(x - 7.5, 0.085, -6.5 + k * 2.6), Color(0.92, 0.92, 0.9), false)
	# Bordures de trottoir du boulevard
	for zb in [-8.1, 8.1]:
		Geo.boite(racine, Vector3(1060, 0.15, 0.25), Vector3(115, 0.07, zb), Color(0.7, 0.7, 0.68), false)
	# Marquage au sol du boulevard
	var xm := -395.0
	while xm < 650.0:
		Geo.boite(racine, Vector3(3, 0.02, 0.2), Vector3(xm, 0.085, 0), Color(0.9, 0.9, 0.9), false)
		xm += 8.0
	# Rivière (le Cher), ponts de la rue et de la rocade
	Geo.boite(racine, Vector3(1800, 0.05, 40), Vector3(100, 0.07, 180), Color(0.2, 0.35, 0.45), false)
	Geo.texte(racine, "Le Cher", Vector3(-120, 2, 180), 120, Color(0.7, 0.85, 1.0))
	for pont in [[100.0, 14.0], [-420.0, 24.0]]:
		var px: float = pont[0]
		var pl: float = pont[1]
		Geo.boite_mat(racine, Vector3(pl, 0.4, 48), Vector3(px, 0.2, 180), Tex.mat_beton(Color(0.8, 0.78, 0.72)))
		for cote in [-1.0, 1.0]:
			Geo.boite(racine, Vector3(0.4, 1.0, 48), Vector3(px + cote * pl * 0.5, 0.9, 180), Color(0.7, 0.67, 0.6))
	# Parapets des quais (on ne tombe pas à l'eau)
	var trous: Array = [[100.0, 14.0, 0.0, 1.0], [-420.0, 24.0, 0.0, 1.0]]
	Geo.mur(racine, "x", 159.5, -800, 1000, 0, 1.0, 0.5, Color(0.7, 0.67, 0.6), trous)
	Geo.mur(racine, "x", 200.5, -800, 1000, 0, 1.0, 0.5, Color(0.7, 0.67, 0.6), trous)
	# Platanes le long du boulevard
	var xa := -300.0
	while xa < 300.0:
		for zz in [-10.5, 10.5]:
			if absf(xa - 160.0) < 6.0 and zz > 0.0:
				continue
			if xa > -285.0 and xa < -212.0 and zz < 0.0:
				continue
			Geo.cylindre(racine, 0.25, 4.5, Vector3(xa, 2.25, zz), Color(0.55, 0.5, 0.42))
			var feuillage := Color(0.24, 0.38, 0.17).lerp(Color(0.36, 0.48, 0.22), rng.randf())
			Geo.sphere(racine, 2.4, Vector3(xa, 5.8, zz), feuillage)
			Geo.sphere(racine, 1.8, Vector3(xa + 1.3, 6.6, zz + 0.6), feuillage.lightened(0.08))
			Geo.sphere(racine, 1.7, Vector3(xa - 1.2, 6.3, zz - 0.7), feuillage.darkened(0.08))
			# Lampadaire entre deux arbres
			_lampadaire(racine, Vector3(xa + 11.0, 0, signf(zz) * 9.0))
		xa += 22.0
	# Îlots d'immeubles
	var blocs_x: Array = [[-320.0, -205.0], [-195.0, -55.0], [-45.0, 95.0], [105.0, 245.0], [255.0, 320.0]]
	for bx in blocs_x:
		_rangee(racine, rng, bx[0], bx[1], -8.0, -1.0)     # côté nord du boulevard
		_rangee(racine, rng, bx[0], bx[1], 8.0, 1.0)       # côté sud du boulevard
		_rangee(racine, rng, bx[0], bx[1], -145.0, 1.0)    # côté sud de la rue du nord
		_rangee(racine, rng, bx[0], bx[1], 115.0, -1.0)    # côté nord de la rue du sud
		_rangee(racine, rng, bx[0], bx[1], 125.0, 1.0)     # maisons de quai, face à la rue du sud
	# Rangées le long des rues nord-sud (on laisse les angles aux rangées est-ouest)
	for xs in [-200.0, -50.0, 100.0, 250.0]:
		for cote in [-1.0, 1.0]:
			for zr in [[-128.0, -30.0], [30.0, 98.0]]:
				_rangee_z(racine, rng, zr[0], zr[1], xs + cote * 5.0, cote)
	# Cœurs d'îlots : jardins, arbres et petites dépendances
	for bx in blocs_x:
		for bz in [[-145.0, -8.0], [8.0, 115.0]]:
			_coeur_ilot(racine, rng, Rect2(bx[0] + 26.0, bz[0] + 26.0, bx[1] - bx[0] - 52.0, bz[1] - bz[0] - 52.0))
	Details.mobilier_centre(racine, rng)
	_voitures_garees(racine, rng)
	Quartiers.construire(racine)
	_caserne(racine)
	_maison(racine)
	_immeuble(racine)
	_hopital(racine)
	# Panneaux de rues
	Geo.texte(racine, Carte.NOM_BOULEVARD, Vector3(40, 4, -9), 56, Color(0.8, 0.9, 1.0))
	Geo.texte(racine, Carte.NOM_RUE_EST, Vector3(244, 4, -40), 56, Color(0.8, 0.9, 1.0))
	Geo.texte(racine, Carte.NOM_RUE_OUEST, Vector3(-56, 4, -40), 56, Color(0.8, 0.9, 1.0))
	# Tous les petits détails regroupés en quelques gros maillages
	Lot.finir(racine)


## Une rangée d'immeubles qui donne sur une rue. "bord" : z du bord de la chaussée.
## "sens" : -1 si les immeubles sont au nord de ce bord, +1 au sud.
static func _rangee(racine: Node3D, rng: RandomNumberGenerator, x0: float, x1: float, bord: float, sens: float) -> void:
	var x := x0 + 2.0
	while x < x1 - 8.0:
		var largeur := rng.randf_range(9.0, 16.0)
		largeur = minf(largeur, x1 - 2.0 - x)
		var profondeur := rng.randf_range(10.0, 14.0)
		var hauteur := rng.randf_range(7.0, 16.0)
		var z_facade := bord + sens * 4.0
		var cz := z_facade + sens * profondeur * 0.5
		var r := Rect2(x, minf(z_facade, z_facade + sens * profondeur), largeur, profondeur)
		var libre := true
		for res in RESERVES:
			var rr: Rect2 = res
			if rr.intersects(r):
				libre = false
		if libre:
			var c: Color = TUFFEAU[rng.randi() % TUFFEAU.size()]
			var hauteur_et: float = floor(hauteur / 3.0) * 3.0
			Geo.boite_mat(racine, Vector3(largeur - 0.4, hauteur_et, profondeur), Vector3(x + largeur * 0.5, hauteur_et * 0.5, cz), Tex.mat_facade(c))
			# Corniche et toit d'ardoise à deux pans
			Geo.boite(racine, Vector3(largeur - 0.1, 0.35, profondeur + 0.3), Vector3(x + largeur * 0.5, hauteur_et + 0.17, cz), Color(0.9, 0.88, 0.82), false)
			Geo.toit(racine, largeur - 0.2, profondeur + 0.4, rng.randf_range(3.0, 4.5), Vector3(x + largeur * 0.5, hauteur_et + 0.35, cz), Tex.mat_ardoise(), true)
			var commerce := rng.randf() < (0.7 if absf(bord) < 10.0 else 0.3)
			Details.immeuble_centre(racine, rng, Vector3(x + largeur * 0.5, 0, z_facade), Vector3(0, 0, -sens), largeur, hauteur_et, profondeur, commerce)
			# Cheminée
			if rng.randf() < 0.6:
				Geo.boite(racine, Vector3(0.7, 2.6, 0.9), Vector3(x + rng.randf_range(1.5, largeur - 1.5), hauteur_et + 2.0, cz + rng.randf_range(-1.5, 1.5)), Color(0.75, 0.68, 0.6), false)
		x += largeur + rng.randf_range(0.0, 1.5)


## Une rangée d'immeubles le long d'une rue nord-sud. "bord" : x du bord de la chaussée.
## "sens" : -1 si les immeubles sont à l'ouest de ce bord, +1 à l'est.
static func _rangee_z(racine: Node3D, rng: RandomNumberGenerator, z0: float, z1: float, bord: float, sens: float) -> void:
	var z := z0
	while z < z1 - 6.0:
		var largeur := minf(rng.randf_range(9.0, 16.0), z1 - z)
		var profondeur := rng.randf_range(10.0, 14.0)
		var hauteur_et: float = floor(rng.randf_range(7.0, 16.0) / 3.0) * 3.0
		var x_facade := bord + sens * 4.0
		var cx := x_facade + sens * profondeur * 0.5
		var r := Rect2(minf(x_facade, x_facade + sens * profondeur), z, profondeur, largeur)
		var libre := true
		for res in RESERVES:
			var rr: Rect2 = res
			if rr.intersects(r):
				libre = false
		if libre:
			var c: Color = TUFFEAU[rng.randi() % TUFFEAU.size()]
			var cz := z + largeur * 0.5
			Geo.boite_mat(racine, Vector3(profondeur, hauteur_et, largeur - 0.4), Vector3(cx, hauteur_et * 0.5, cz), Tex.mat_facade(c))
			Geo.boite(racine, Vector3(profondeur + 0.3, 0.35, largeur - 0.1), Vector3(cx, hauteur_et + 0.17, cz), Color(0.9, 0.88, 0.82), false)
			Geo.toit(racine, profondeur + 0.4, largeur - 0.2, rng.randf_range(3.0, 4.5), Vector3(cx, hauteur_et + 0.35, cz), Tex.mat_ardoise(), false)
			Details.immeuble_centre(racine, rng, Vector3(x_facade, 0, cz), Vector3(-sens, 0, 0), largeur, hauteur_et, profondeur, rng.randf() < 0.3)
			if rng.randf() < 0.6:
				Geo.boite(racine, Vector3(0.9, 2.6, 0.7), Vector3(cx + rng.randf_range(-1.5, 1.5), hauteur_et + 2.0, z + rng.randf_range(1.5, largeur - 1.5)), Color(0.75, 0.68, 0.6), false)
		z += largeur + rng.randf_range(0.0, 1.5)


## Le cœur d'un îlot du centre : jardins privés, arbres, murets et petites dépendances.
static func _coeur_ilot(racine: Node3D, rng: RandomNumberGenerator, r: Rect2) -> void:
	for res in RESERVES:
		var rr: Rect2 = res
		if r.size.x < 20.0:
			return
		if rr.grow(4.0).intersects(r):
			# On laisse de la place au bâtiment réservé (caserne, immeuble du feu…)
			if rr.get_center().x < r.get_center().x:
				var fin := r.end.x
				r.position.x = rr.end.x + 6.0
				r.size.x = fin - r.position.x
			else:
				r.size.x = rr.position.x - 6.0 - r.position.x
	if r.size.x < 20.0:
		return
	var c: Vector2 = r.get_center()
	Geo.boite_mat(racine, Vector3(r.size.x, 0.05, r.size.y), Vector3(c.x, 0.06, c.y), Tex.mat_herbe(), false)
	# Murets de séparation des jardins
	var x := r.position.x + rng.randf_range(12.0, 20.0)
	while x < r.end.x - 8.0:
		Geo.boite(racine, Vector3(0.4, 1.8, r.size.y), Vector3(x, 0.9, c.y), Color(0.82, 0.78, 0.68), false)
		x += rng.randf_range(14.0, 22.0)
	Geo.boite(racine, Vector3(r.size.x, 1.8, 0.4), Vector3(c.x, 0.9, c.y), Color(0.82, 0.78, 0.68), false)
	# Arbres
	for k in int(r.size.x * r.size.y / 500.0):
		var p := Vector3(rng.randf_range(r.position.x + 3.0, r.end.x - 3.0), 0, rng.randf_range(r.position.y + 3.0, r.end.y - 3.0))
		var t := rng.randf_range(0.8, 1.3)
		Geo.cylindre(racine, 0.22 * t, 4.0 * t, p + Vector3(0, 2.0 * t, 0), Color(0.5, 0.42, 0.33))
		Geo.sphere(racine, 2.3 * t, p + Vector3(0, 5.0 * t, 0), Color(0.22, 0.36, 0.16).lerp(Color(0.38, 0.5, 0.22), rng.randf()))
	# Dépendances (ateliers, remises) à toit d'ardoise
	for k in 3:
		var l := rng.randf_range(6.0, 10.0)
		var p2 := Vector3(rng.randf_range(r.position.x + 6.0, r.end.x - 6.0), 0, rng.randf_range(r.position.y + 5.0, r.end.y - 5.0))
		Geo.boite_mat(racine, Vector3(l, 3.0, 6.0), p2 + Vector3(0, 1.5, 0), Tex.mat_facade(TUFFEAU[k % TUFFEAU.size()]))
		Geo.toit(racine, l, 6.4, 1.8, p2 + Vector3(0, 3.0, 0), Tex.mat_ardoise(), true)


## Trace les chaussées à partir des noeuds et des rues du plan.
static func _routes(racine: Node3D) -> void:
	var asph: Material = Tex.mat_asphalte()
	var deja: Dictionary = {}
	for ar in Carte.ARETES:
		var a: Vector3 = Carte.NOEUDS[ar[0]]
		var b: Vector3 = Carte.NOEUDS[ar[1]]
		var l: float = Carte.largeur_arete(ar[0], ar[1])
		var milieu: Vector3 = (a + b) * 0.5
		var longueur: float = a.distance_to(b)
		var hauteur := 0.05 if l >= 16.0 else 0.055
		if absf(a.x - b.x) < 0.5:
			Geo.boite_mat(racine, Vector3(l, 0.05, longueur), Vector3(milieu.x, hauteur, milieu.z), asph, false)
		else:
			Geo.boite_mat(racine, Vector3(longueur, 0.05, l), Vector3(milieu.x, hauteur, milieu.z), asph, false)
		# Carrefours : on remplit le coin
		for n in [ar[0], ar[1]]:
			if not deja.has(n):
				deja[n] = true
				var p: Vector3 = Carte.NOEUDS[n]
				Geo.boite_mat(racine, Vector3(l, 0.05, l), Vector3(p.x, 0.053, p.z), asph, false)


static func _lampadaire(racine: Node3D, pos: Vector3) -> void:
	Geo.cylindre(racine, 0.08, 6.0, pos + Vector3(0, 3.0, 0), Color(0.18, 0.2, 0.22))
	var bras: Node3D = Geo.boite(racine, Vector3(0.12, 0.12, 1.4), pos + Vector3(0, 6.0, -signf(pos.z) * 0.6), Color(0.18, 0.2, 0.22), false)
	bras.name = "bras"
	Geo.boite(racine, Vector3(0.5, 0.2, 0.7), pos + Vector3(0, 5.9, -signf(pos.z) * 1.2), Color(0.18, 0.2, 0.22), false)
	Geo.boite_mat(racine, Vector3(0.4, 0.04, 0.6), pos + Vector3(0, 5.79, -signf(pos.z) * 1.2), Geo.mat(Color(1.0, 0.93, 0.78), 1.2), false)


static func _voitures_garees(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var couleurs: Array = [Color(0.15, 0.2, 0.4), Color(0.6, 0.6, 0.62), Color(0.08, 0.08, 0.1), Color(0.5, 0.1, 0.1), Color(0.85, 0.85, 0.85), Color(0.3, 0.35, 0.3)]
	# Le long des rues nord-sud, côté gauche (stationnement)
	for x in [-200.0, 100.0, 250.0, -50.0]:
		var z := -130.0
		while z < 100.0:
			if absf(z) > 14.0 and rng.randf() < 0.45:
				if not (x == 250.0 and z > -100.0 and z < -78.0) and not (x == -50.0 and z > -115.0 and z < -60.0):
					_voiture(racine, Vector3(x - 3.6, 0, z), couleurs[rng.randi() % couleurs.size()])
			z += 6.0


static func _voiture(racine: Node3D, pos: Vector3, c: Color) -> void:
	var types: Array = VoitureModele.TYPES
	var t: String = types[absi(int(pos.x * 7.0 + pos.z * 13.0)) % types.size()]
	VoitureModele.garer(Lot, t, c, pos, Basis.IDENTITY if int(pos.z) % 2 == 0 else Basis(Vector3.UP, PI))
	# On ne traverse pas les voitures garées
	var corps := StaticBody3D.new()
	corps.position = pos + Vector3(0, 0.75, 0)
	racine.add_child(corps)
	var cs := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.8, 1.3, 4.3)
	cs.shape = forme
	corps.add_child(cs)


static func _caserne(racine: Node3D) -> void:
	var gris := Color(0.82, 0.82, 0.8)
	var rouge := Color(0.7, 0.1, 0.08)
	# Sol de la remise et cour
	var bet: Material = Tex.mat_beton()
	Geo.boite_mat(racine, Vector3(70, 0.06, 64), Vector3(-250, 0.09, -40), Tex.mat_beton(Color(0.75, 0.75, 0.73)), false)
	# Murs : fond, côtés, façade avec deux grandes portes de remise et une porte piétonne
	Geo.mur(racine, "x", -70.0, -285.0, -215.0, 0.0, 7.0, 0.4, gris, [], bet)
	Geo.mur(racine, "z", -285.0, -70.0, -14.0, 0.0, 7.0, 0.4, gris, [], bet)
	Geo.mur(racine, "z", -215.0, -70.0, -14.0, 0.0, 7.0, 0.4, gris, [], bet)
	Geo.mur(racine, "x", -14.0, -285.0, -215.0, 0.0, 7.0, 0.4, gris, [
		[-262.0, 5.0, 0.0, 4.6], [-238.0, 5.0, 0.0, 4.6], [-278.0, 1.6, 0.0, 2.3]], bet)
	# Encadrements rouges des portes de remise et rideaux relevés
	for px in [-262.0, -238.0]:
		for cote in [-1.0, 1.0]:
			Geo.boite(racine, Vector3(0.3, 4.6, 0.5), Vector3(px + cote * 2.6, 2.3, -13.9), rouge, false)
		Geo.boite(racine, Vector3(5.5, 0.3, 0.5), Vector3(px, 4.75, -13.9), rouge, false)
		Geo.boite_mat(racine, Vector3(5.0, 0.6, 0.6), Vector3(px, 4.3, -14.3), Tex.plaque("rideau", Tex.rideau(), 0.5, 0.5), false)
	# Bandes du sol devant la remise
	for px in [-262.0, -238.0]:
		Geo.boite(racine, Vector3(4.0, 0.02, 0.4), Vector3(px, 0.13, -11.0), Color(0.95, 0.8, 0.1), false)
	# Éclairage de la remise : tubes néon au plafond
	for nx in [-270.0, -250.0, -230.0]:
		for nz in [-24.0, -42.0, -60.0]:
			Geo.boite_mat(racine, Vector3(0.25, 0.08, 4.0), Vector3(nx, 6.85, nz), Tex.emissif(Color(1.0, 0.98, 0.92), 2.0), false)
			var lum := OmniLight3D.new()
			lum.position = Vector3(nx, 6.2, nz)
			lum.omni_range = 14.0
			lum.light_energy = 0.9
			lum.light_color = Color(1.0, 0.97, 0.9)
			racine.add_child(lum)
	# Tour de séchage des tuyaux
	Geo.boite_mat(racine, Vector3(4, 16, 4), Vector3(-219, 8, -66), bet)
	Geo.boite(racine, Vector3(4.3, 0.6, 4.3), Vector3(-219, 16.2, -66), rouge, false)
	Geo.boite(racine, Vector3(70.6, 0.5, 56.6), Vector3(-250, 7.2, -42), Color(0.45, 0.45, 0.45))
	Geo.boite(racine, Vector3(70.6, 0.8, 0.3), Vector3(-250, 6.0, -13.7), rouge, false)
	var enseigne: Label3D = Geo.texte(racine, "CENTRE DE SECOURS DE JOUÉ-LÈS-TOURS", Vector3(-250, 5.3, -13.5), 90, Color.WHITE, false)
	enseigne.outline_size = 12
	Geo.texte(racine, "SDIS fictif de Touraine", Vector3(-250, 8.6, -14), 60, Color(1, 0.85, 0.8))
	# Cloison entre la remise et le vestiaire / salle de garde
	Geo.mur(racine, "x", -54.0, -285.0, -215.0, 0.0, 3.2, 0.2, Color(0.9, 0.88, 0.82), [[-276.0, 2.0, 0.0, 2.2], [-250.0, 2.0, 0.0, 2.2], [-224.0, 2.0, 0.0, 2.2]])
	# Vestiaire : casiers
	for i in 8:
		Geo.boite(racine, Vector3(1.0, 2.0, 0.6), Vector3(-284.0 + 0.5 + i * 1.05, 1.0, -69.4), Color(0.35, 0.45, 0.6))
	Geo.texte(racine, "VESTIAIRE", Vector3(-276, 2.8, -66), 48, Color(1, 1, 0.7))
	# Salle de garde : table et chaises
	Geo.boite(racine, Vector3(4, 0.9, 1.6), Vector3(-238, 0.45, -62), Color(0.5, 0.35, 0.2))
	Geo.texte(racine, "SALLE DE GARDE", Vector3(-238, 2.8, -66), 40, Color(1, 1, 0.7))
	# Places de stationnement des engins
	Geo.boite(racine, Vector3(3.6, 0.02, 9.5), Carte.PARKING_VSAV + Vector3(0, 0.12, 0), Color(0.9, 0.8, 0.2, 0.5), false)
	Geo.boite(racine, Vector3(3.6, 0.02, 9.5), Carte.PARKING_FPT + Vector3(0, 0.12, 0), Color(0.9, 0.8, 0.2, 0.5), false)


static func _maison(racine: Node3D) -> void:
	var c := Color(0.9, 0.86, 0.76)
	var fac: Material = Tex.plaque("tuffeau_uni", Tex.beton(), 3.0, 3.0, Color(0.95, 0.9, 0.78))
	Geo.boite(racine, Vector3(14, 0.06, 16), Vector3(264, 0.1, -91), Color(0.5, 0.42, 0.35), false)
	Geo.mur(racine, "z", 258.0, -98.0, -84.0, 0.0, 3.0, 0.3, c, [[-91.0, 1.4, 0.0, 2.2], [-95.0, 1.2, 1.0, 2.0], [-87.0, 1.2, 1.0, 2.0]], fac)
	Geo.mur(racine, "z", 270.0, -98.0, -84.0, 0.0, 3.0, 0.3, c, [], fac)
	Geo.mur(racine, "x", -98.0, 258.0, 270.0, 0.0, 3.0, 0.3, c, [], fac)
	Geo.mur(racine, "x", -84.0, 258.0, 270.0, 0.0, 3.0, 0.3, c, [], fac)
	Geo.boite(racine, Vector3(13, 0.3, 15), Vector3(264, 3.15, -91), c)
	Geo.toit(racine, 13.6, 15.6, 3.5, Vector3(264, 3.3, -91), Tex.mat_ardoise(), false)
	# Porte d'entrée ouverte et intérieur
	Geo.boite(racine, Vector3(0.08, 2.2, 1.3), Vector3(258.6, 1.1, -90.2), Color(0.35, 0.22, 0.15), false)
	Geo.boite(racine, Vector3(11.4, 0.04, 13.4), Vector3(264, 0.14, -91), Color(0.55, 0.38, 0.25), false)
	# Mobilier
	Geo.boite(racine, Vector3(2.0, 0.5, 0.9), Vector3(268, 0.25, -88), Color(0.4, 0.3, 0.5))
	Geo.boite(racine, Vector3(1.2, 0.75, 1.2), Vector3(266, 0.37, -95), Color(0.5, 0.35, 0.2))
	Geo.texte(racine, "8, " + Carte.NOM_RUE_EST, Vector3(257.5, 3.0, -91), 36, Color(1, 1, 1))


static func _immeuble(racine: Node3D) -> void:
	var c := Color(0.85, 0.80, 0.68)
	var fen: Array = []
	for niveau in [0.0, 3.0, 6.0]:
		for zc in [-101.0, -93.5, -87.5, -82.5]:
			fen.append([zc, 1.2, niveau + 0.9, niveau + 2.3])
	var facade: Array = fen.duplicate()
	facade.append([-95.0, 1.6, 0.0, 2.4])   # porte d'entrée
	# On retire la fenêtre du rez-de-chaussée qui chevaucherait la porte
	facade = facade.filter(func(o): return not (absf(o[0] - (-93.5)) < 0.1 and o[2] < 1.0))
	var fac: Material = Tex.plaque("tuffeau_uni", Tex.beton(), 3.0, 3.0, Color(0.95, 0.9, 0.78))
	Geo.mur(racine, "z", -41.0, -110.0, -80.0, 0.0, 9.5, 0.3, c, facade, fac)
	Geo.mur(racine, "z", -23.0, -110.0, -80.0, 0.0, 9.5, 0.3, c, fen, fac)
	Geo.mur(racine, "x", -110.0, -41.0, -23.0, 0.0, 9.5, 0.3, c, [], fac)
	Geo.mur(racine, "x", -80.0, -41.0, -23.0, 0.0, 9.5, 0.3, c, [], fac)
	# Volets autour des fenêtres de la façade sur rue
	for o in fen:
		for cote in [-1.0, 1.0]:
			Geo.boite(racine, Vector3(0.06, 1.4, 0.55), Vector3(-41.2, (o[2] + o[3]) * 0.5, o[0] + cote * 0.9), Color(0.42, 0.5, 0.56), false)
	# Planchers (1er, 2e) et toit
	Geo.boite(racine, Vector3(18, 0.2, 30), Vector3(-32, 3.0, -95), Color(0.6, 0.58, 0.55))
	Geo.boite(racine, Vector3(18, 0.2, 30), Vector3(-32, 6.0, -95), Color(0.55, 0.45, 0.35))
	Geo.boite(racine, Vector3(18.4, 0.3, 30.4), Vector3(-32, 9.6, -95), c)
	Geo.toit(racine, 18.8, 30.8, 4.0, Vector3(-32, 9.75, -95), Tex.mat_ardoise(), false)
	# Cloisons de l'appartement du 2e étage (portes au milieu)
	var cloison := Color(0.92, 0.9, 0.85)
	for zc in [-104.0, -98.0, -90.0, -85.0]:
		Geo.mur(racine, "x", zc, -41.0, -23.0, 6.1, 3.4, 0.15, cloison, [[-32.0, 1.2, 6.1, 8.3]])
	# Mobilier : canapé, table de cuisine, lit
	Geo.boite(racine, Vector3(3.0, 0.8, 1.0), Vector3(-27.0, 6.5, -95.0), Color(0.3, 0.3, 0.45))
	Geo.boite(racine, Vector3(1.5, 0.9, 1.0), Vector3(-37.0, 6.55, -87.5), Color(0.5, 0.35, 0.2))
	Geo.boite(racine, Vector3(2.0, 0.5, 1.6), Vector3(-26.5, 6.35, -82.5), Color(0.8, 0.8, 0.85))
	# Cage d'escalier (simplifiée : on monte en appuyant sur E)
	Geo.boite(racine, Vector3(3, 0.05, 3), Vector3(-36.0, 6.12, -107.5), Color(0.5, 0.5, 0.5), false)
	Geo.texte(racine, "Escalier", Vector3(-38.5, 7.8, -108), 32, Color(1, 1, 0.7))
	Geo.texte(racine, "21, " + Carte.NOM_RUE_OUEST, Vector3(-41.5, 3.0, -95), 36, Color(1, 1, 1))
	# Poteau d'incendie (PI)
	Geo.cylindre(racine, 0.22, 1.0, Carte.POTEAU_INCENDIE + Vector3(0, 0.5, 0), Color(0.85, 0.1, 0.1))
	Geo.texte(racine, "PI", Carte.POTEAU_INCENDIE + Vector3(0, 1.4, 0), 32, Color(1, 0.7, 0.7))


static func _hopital(racine: Node3D) -> void:
	Geo.boite(racine, Vector3(36, 14, 30), Vector3(182, 7, 266), Color(0.93, 0.93, 0.95))
	Geo.boite(racine, Vector3(12, 0.4, 5), Vector3(180, 3.5, 249), Color(0.8, 0.15, 0.15), false)
	Geo.texte(racine, "CENTRE HOSPITALIER — URGENCES", Vector3(182, 6, 250.6), 80, Color(0.9, 0.1, 0.1))
