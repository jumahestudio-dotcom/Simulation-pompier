## Construit le quartier : sol, rues, rivière, pont, immeubles en tuffeau aux toits d'ardoise,
## la caserne, la maison, l'immeuble du feu et le centre hospitalier.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Carte = preload("res://scripts/carte.gd")

const TUFFEAU: Array = [Color(0.87, 0.83, 0.71), Color(0.82, 0.78, 0.67), Color(0.92, 0.89, 0.80), Color(0.78, 0.73, 0.62)]
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
	# Sol (herbe et trottoirs)
	Geo.boite(racine, Vector3(900, 1, 800), Vector3(0, -0.5, 30), Color(0.36, 0.45, 0.28))
	Geo.boite(racine, Vector3(660, 0.04, 420), Vector3(0, 0.02, -15), TROTTOIR, false)
	# Boulevard et rues
	Geo.boite(racine, Vector3(660, 0.05, 16), Vector3(0, 0.05, 0), ROUTE, false)
	Geo.boite(racine, Vector3(460, 0.05, 10), Vector3(25, 0.05, -150), ROUTE, false)
	Geo.boite(racine, Vector3(460, 0.05, 10), Vector3(25, 0.05, 120), ROUTE, false)
	for x in [-200.0, -50.0, 100.0, 250.0]:
		Geo.boite(racine, Vector3(10, 0.05, 280), Vector3(x, 0.055, -15), ROUTE, false)
	Geo.boite(racine, Vector3(10, 0.05, 130), Vector3(100, 0.055, 180), ROUTE, false)
	Geo.boite(racine, Vector3(110, 0.05, 10), Vector3(140, 0.055, 240), ROUTE, false)
	# Marquage au sol du boulevard
	var xm := -320.0
	while xm < 320.0:
		Geo.boite(racine, Vector3(3, 0.02, 0.2), Vector3(xm, 0.085, 0), Color(0.9, 0.9, 0.9), false)
		xm += 8.0
	# Rivière (le Cher) et pont
	Geo.boite(racine, Vector3(900, 0.05, 40), Vector3(0, 0.07, 180), Color(0.2, 0.35, 0.45), false)
	Geo.texte(racine, "Le Cher", Vector3(-120, 2, 180), 120, Color(0.7, 0.85, 1.0))
	Geo.boite(racine, Vector3(14, 0.4, 48), Vector3(100, 0.2, 180), Color(0.6, 0.58, 0.52))
	for cote in [-1.0, 1.0]:
		Geo.boite(racine, Vector3(0.4, 1.0, 48), Vector3(100 + cote * 7.0, 0.9, 180), Color(0.7, 0.67, 0.6))
	# Parapets des quais (on ne tombe pas à l'eau)
	Geo.mur(racine, "x", 159.5, -450, 450, 0, 1.0, 0.5, Color(0.7, 0.67, 0.6), [[100.0, 14.0, 0.0, 1.0]])
	Geo.mur(racine, "x", 200.5, -450, 450, 0, 1.0, 0.5, Color(0.7, 0.67, 0.6), [[100.0, 14.0, 0.0, 1.0]])
	# Platanes le long du boulevard
	var xa := -300.0
	while xa < 300.0:
		for zz in [-10.5, 10.5]:
			if absf(xa - 160.0) < 6.0 and zz > 0.0:
				continue
			if xa > -285.0 and xa < -212.0 and zz < 0.0:
				continue
			Geo.cylindre(racine, 0.25, 4.0, Vector3(xa, 2.0, zz), Color(0.4, 0.33, 0.25))
			Geo.sphere(racine, 2.6, Vector3(xa, 5.5, zz), Color(0.25, 0.42, 0.2))
		xa += 22.0
	# Îlots d'immeubles
	var blocs_x: Array = [[-320.0, -205.0], [-195.0, -55.0], [-45.0, 95.0], [105.0, 245.0], [255.0, 320.0]]
	for bx in blocs_x:
		_rangee(racine, rng, bx[0], bx[1], -8.0, -1.0)     # côté nord du boulevard
		_rangee(racine, rng, bx[0], bx[1], 8.0, 1.0)       # côté sud du boulevard
		_rangee(racine, rng, bx[0], bx[1], -145.0, 1.0)    # côté sud de la rue du nord
		_rangee(racine, rng, bx[0], bx[1], 115.0, -1.0)    # côté nord de la rue du sud
	_caserne(racine)
	_maison(racine)
	_immeuble(racine)
	_hopital(racine)
	# Panneaux de rues
	Geo.texte(racine, Carte.NOM_BOULEVARD, Vector3(40, 4, -9), 56, Color(0.8, 0.9, 1.0))
	Geo.texte(racine, Carte.NOM_RUE_EST, Vector3(244, 4, -40), 56, Color(0.8, 0.9, 1.0))
	Geo.texte(racine, Carte.NOM_RUE_OUEST, Vector3(-56, 4, -40), 56, Color(0.8, 0.9, 1.0))


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
			Geo.boite(racine, Vector3(largeur - 0.4, hauteur, profondeur), Vector3(x + largeur * 0.5, hauteur * 0.5, cz), c)
			# Toit d'ardoise
			Geo.boite(racine, Vector3(largeur - 0.2, 1.6, profondeur + 0.2), Vector3(x + largeur * 0.5, hauteur + 0.8, cz), ARDOISE, false)
			# Rangées de fenêtres sur la façade
			var etage := 3.0
			while etage < hauteur - 1.0:
				Geo.boite(racine, Vector3(largeur - 2.0, 1.3, 0.05), Vector3(x + largeur * 0.5, etage, z_facade - sens * 0.03), Color(0.25, 0.3, 0.36), false)
				etage += 3.0
		x += largeur + rng.randf_range(0.0, 1.5)


static func _caserne(racine: Node3D) -> void:
	var gris := Color(0.82, 0.82, 0.8)
	var rouge := Color(0.7, 0.1, 0.08)
	# Sol de la remise et cour
	Geo.boite(racine, Vector3(70, 0.06, 64), Vector3(-250, 0.09, -40), Color(0.62, 0.62, 0.6), false)
	# Murs : fond, côtés, façade avec deux grandes portes de remise et une porte piétonne
	Geo.mur(racine, "x", -70.0, -285.0, -215.0, 0.0, 7.0, 0.4, gris)
	Geo.mur(racine, "z", -285.0, -70.0, -14.0, 0.0, 7.0, 0.4, gris)
	Geo.mur(racine, "z", -215.0, -70.0, -14.0, 0.0, 7.0, 0.4, gris)
	Geo.mur(racine, "x", -14.0, -285.0, -215.0, 0.0, 7.0, 0.4, gris, [
		[-262.0, 5.0, 0.0, 4.6], [-238.0, 5.0, 0.0, 4.6], [-278.0, 1.6, 0.0, 2.3]])
	Geo.boite(racine, Vector3(70.6, 0.5, 56.6), Vector3(-250, 7.2, -42), rouge)
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
	Geo.boite(racine, Vector3(14, 0.06, 16), Vector3(264, 0.1, -91), Color(0.5, 0.42, 0.35), false)
	Geo.mur(racine, "z", 258.0, -98.0, -84.0, 0.0, 3.0, 0.3, c, [[-91.0, 1.4, 0.0, 2.2], [-95.0, 1.2, 1.0, 2.0], [-87.0, 1.2, 1.0, 2.0]])
	Geo.mur(racine, "z", 270.0, -98.0, -84.0, 0.0, 3.0, 0.3, c)
	Geo.mur(racine, "x", -98.0, 258.0, 270.0, 0.0, 3.0, 0.3, c)
	Geo.mur(racine, "x", -84.0, 258.0, 270.0, 0.0, 3.0, 0.3, c)
	Geo.boite(racine, Vector3(13, 0.3, 15), Vector3(264, 3.15, -91), c)
	var toit: Node3D = Geo.boite(racine, Vector3(13.5, 0.4, 15.5), Vector3(264, 3.9, -91), ARDOISE, false)
	toit.scale = Vector3(1, 4, 1)
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
	Geo.mur(racine, "z", -41.0, -110.0, -80.0, 0.0, 9.5, 0.3, c, facade)
	Geo.mur(racine, "z", -23.0, -110.0, -80.0, 0.0, 9.5, 0.3, c, fen)
	Geo.mur(racine, "x", -110.0, -41.0, -23.0, 0.0, 9.5, 0.3, c)
	Geo.mur(racine, "x", -80.0, -41.0, -23.0, 0.0, 9.5, 0.3, c)
	# Planchers (1er, 2e) et toit
	Geo.boite(racine, Vector3(18, 0.2, 30), Vector3(-32, 3.0, -95), Color(0.6, 0.58, 0.55))
	Geo.boite(racine, Vector3(18, 0.2, 30), Vector3(-32, 6.0, -95), Color(0.55, 0.45, 0.35))
	Geo.boite(racine, Vector3(18.4, 0.3, 30.4), Vector3(-32, 9.6, -95), c)
	Geo.boite(racine, Vector3(18.6, 1.8, 30.6), Vector3(-32, 10.6, -95), ARDOISE, false)
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
