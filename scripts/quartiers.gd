## Les quartiers autour du centre ancien, inspirés de l'agglomération tourangelle (sans la copier) :
## grands ensembles, pavillons, zone d'activités, rocade, bords du Cher, rive sud et campagne.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")
const Lot = preload("res://scripts/lot.gd")
const VoitureModele = preload("res://scripts/voiture_modele.gd")
const Details = preload("res://scripts/details.gd")
const Nature = preload("res://scripts/nature.gd")

const COULEURS_VOITURES: Array = [Color(0.15, 0.2, 0.4), Color(0.6, 0.6, 0.62), Color(0.08, 0.08, 0.1), Color(0.5, 0.1, 0.1), Color(0.85, 0.85, 0.85), Color(0.3, 0.35, 0.3), Color(0.75, 0.7, 0.6)]


static func construire(racine: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1137
	_grands_ensembles(racine, rng)
	_pavillons_nord(racine, rng)
	_zone_activites(racine, rng)
	_densifier_tilleuls(racine, rng)
	_densifier_ormeaux(racine, rng)
	_rocade(racine, rng)
	_bords_du_cher(racine, rng)
	_rive_sud(racine, rng)
	_campagne(racine, rng)
	_panneaux(racine)
	Nature.construire(racine)


# ---------------------------------------------------------------------------
# Petits éléments réutilisés
# ---------------------------------------------------------------------------

static func _voiture(racine: Node3D, pos: Vector3, c: Color, angle: float = 0.0) -> void:
	# Le modèle dépend de la position (toujours le même au même endroit)
	var types: Array = VoitureModele.TYPES
	var t: String = types[absi(int(pos.x * 7.0 + pos.z * 13.0)) % types.size()]
	VoitureModele.garer(Lot, t, c, pos, Basis(Vector3.UP, angle))


static func _arbre(_racine: Node3D, pos: Vector3, rng: RandomNumberGenerator, taille: float = 1.0) -> void:
	Details.arbre(pos, taille, rng)


static func _parking(racine: Node3D, r: Rect2, rng: RandomNumberGenerator, remplissage: float) -> void:
	var c: Vector2 = r.get_center()
	Geo.boite_mat(racine, Vector3(r.size.x, 0.05, r.size.y), Vector3(c.x, 0.06, c.y), Tex.mat_asphalte(), false)
	# Places de 2,5 m sur deux rangées
	var x := r.position.x + 1.5
	while x < r.end.x - 2.0:
		for rangee in [0, 1]:
			var zc: float = r.position.y + 3.0 + rangee * (r.size.y - 6.0)
			Geo.boite(racine, Vector3(0.12, 0.02, 5.0), Vector3(x, 0.09, zc), Color(0.92, 0.92, 0.9), false)
			if rng.randf() < remplissage and x + 2.5 < r.end.x:
				_voiture(racine, Vector3(x + 1.25, 0, zc), COULEURS_VOITURES[rng.randi() % COULEURS_VOITURES.size()], 0.0)
		x += 2.5


static func _tour(racine: Node3D, centre: Vector3, l: float, p: float, h: float, teinte: Color) -> void:
	Geo.boite_mat(racine, Vector3(l, h, p), centre + Vector3(0, h * 0.5, 0), Tex.plaque("hlm", Tex.facade_hlm(), 3.0, 3.0, teinte))
	Geo.boite(racine, Vector3(l + 0.4, 0.6, p + 0.4), centre + Vector3(0, h + 0.3, 0), Color(0.62, 0.62, 0.6), false)
	Geo.boite(racine, Vector3(4, 3, 4), centre + Vector3(0, h + 1.8, 0), Color(0.75, 0.75, 0.72), false)
	# Hall d'entrée vitré sur les deux grandes faces, avec auvent et interphone
	for cote in [-1.0, 1.0]:
		Lot.boite(Vector3(4, 2.6, 0.2), centre + Vector3(0, 1.3, cote * (p * 0.5 + 0.05)), Tex.vitre())
		Lot.boite_c(Vector3(5.0, 0.25, 2.2), centre + Vector3(0, 2.9, cote * (p * 0.5 + 1.1)), Color(0.55, 0.55, 0.55))
		Lot.boite_c(Vector3(0.3, 0.45, 0.1), centre + Vector3(2.4, 1.3, cote * (p * 0.5 + 0.08)), Color(0.6, 0.62, 0.65))
	# Soubassement plus sombre au rez-de-chaussée
	Lot.boite_c(Vector3(l + 0.1, 0.9, p + 0.1), centre + Vector3(0, 0.45, 0), Color(0.55, 0.55, 0.53))
	# Loggias et balcons sur chaque face, garde-corps à panneaux de couleur
	var accent: Color = [Color(0.8, 0.45, 0.25), Color(0.3, 0.5, 0.7), Color(0.55, 0.65, 0.3), Color(0.75, 0.6, 0.25)][int(absf(centre.x + centre.z)) % 4]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(centre.x * 7.0 + centre.z * 13.0))
	var faces := [[Vector3(0, 0, 1), l, p], [Vector3(0, 0, -1), l, p], [Vector3(1, 0, 0), p, l], [Vector3(-1, 0, 0), p, l]]
	for f in faces:
		var n: Vector3 = f[0]
		var largeur: float = f[1]
		var prof: float = f[2]
		var t := Vector3.UP.cross(n)
		var b := Basis(t, Vector3.UP, n)
		var nb_baies := int(largeur / 6.0)
		if nb_baies < 1:
			continue
		var etages := int(h / 3.0)
		for k in nb_baies:
			if k % 2 == 1 and largeur < 20.0:
				continue
			var a: float = -largeur * 0.5 + (k + 0.5) * largeur / nb_baies
			for e in range(1, etages):
				var pos: Vector3 = centre + t * a + n * (prof * 0.5 + 0.6) + Vector3(0, e * 3.0, 0)
				Lot.boite(Vector3(3.6, 0.18, 1.2), pos, Lot.couleur(Color(0.82, 0.82, 0.8)), b)
				Lot.boite(Vector3(3.6, 1.0, 0.08), pos + n * 0.58 + Vector3(0, 0.55, 0), Lot.couleur(accent if e % 2 == 0 else Color(0.9, 0.9, 0.88)), b)
				if rng.randf() < 0.18:
					Lot.sphere(0.4, pos + n * 0.4 + t * 1.3 + Vector3(0, 1.4, 0), Lot.couleur(Color(0.85, 0.85, 0.85)), 0.35)
				elif rng.randf() < 0.15:
					Lot.boite_c(Vector3(1.0, 0.8, 0.5), pos + n * 0.2 - t * 1.2 + Vector3(0, 0.5, 0), Color(0.3, 0.45, 0.25))
	# Garde-corps et antennes sur le toit
	Lot.boite_c(Vector3(l, 1.0, 0.1), centre + Vector3(0, h + 1.1, p * 0.5), Color(0.6, 0.6, 0.6))
	Lot.boite_c(Vector3(l, 1.0, 0.1), centre + Vector3(0, h + 1.1, -p * 0.5), Color(0.6, 0.6, 0.6))
	for k in 3:
		Lot.cylindre(0.05, 3.0, centre + Vector3(-l * 0.3 + k * l * 0.3, h + 2.1, -p * 0.3), Lot.couleur(Color(0.5, 0.5, 0.5)))


static func _maison(racine: Node3D, avant: Vector3, face: float, rng: RandomNumberGenerator) -> void:
	# "avant" : milieu du bord de la parcelle côté rue. "face" : +1 si la rue est vers +z, -1 sinon.
	var larg := rng.randf_range(8.0, 11.0)
	var prof := rng.randf_range(7.0, 9.0)
	var etage := rng.randf() < 0.5
	var h := 5.6 if etage else 3.0
	var centre := avant + Vector3(rng.randf_range(-1.5, 1.5), 0, -face * (6.0 + prof * 0.5))
	var teinte: Color = [Color(1, 0.98, 0.92), Color(0.98, 0.92, 0.82), Color(0.95, 0.95, 0.95), Color(0.96, 0.88, 0.78)][rng.randi() % 4]
	Geo.boite_mat(racine, Vector3(larg, h, prof), centre + Vector3(0, h * 0.5, 0), Tex.plaque("crepi", Tex.crepi(), 3.0, 2.8, teinte))
	var toit_mat: Material = Tex.plaque("tuiles", Tex.tuiles(), 2.0, 2.0) if rng.randf() < 0.55 else Tex.mat_ardoise()
	Geo.toit(racine, larg + 0.6, prof + 0.6, rng.randf_range(2.2, 3.4), centre + Vector3(0, h, 0), toit_mat, true)
	# Porte d'entrée côté rue
	Lot.boite_c(Vector3(1.0, 2.1, 0.1), centre + Vector3(larg * 0.2, 1.05, face * (prof * 0.5 + 0.03)), Color(0.35, 0.25, 0.18))
	# Garage accolé
	if rng.randf() < 0.6:
		var gx: float = centre.x + (larg * 0.5 + 2.2) * (1.0 if rng.randf() < 0.5 else -1.0)
		Geo.boite_mat(racine, Vector3(4.2, 2.7, 6.0), Vector3(gx, 1.35, centre.z + face * (prof * 0.5 - 3.0)), Tex.plaque("crepi_uni", Tex.beton(), 3.0, 3.0, teinte))
		Lot.boite(Vector3(2.6, 2.1, 0.08), Vector3(gx, 1.05, centre.z + face * (prof * 0.5 + 0.02)), Tex.plaque("rideau", Tex.rideau(), 0.5, 0.5, Color(0.85, 0.85, 0.85)))
		if rng.randf() < 0.6:
			_voiture(racine, Vector3(gx, 0, avant.z - face * 3.2), COULEURS_VOITURES[rng.randi() % COULEURS_VOITURES.size()], 0.0)
	# Haie ou muret le long de la rue, avec une ouverture
	var haie := Color(0.18, 0.32, 0.14) if rng.randf() < 0.7 else Color(0.85, 0.83, 0.78)
	Lot.boite_c(Vector3(6.0, 1.1, 0.6), avant + Vector3(-4.5, 0.55, -face * 0.4), haie)
	Lot.boite_c(Vector3(4.0, 1.1, 0.6), avant + Vector3(5.5, 0.55, -face * 0.4), haie)
	Details.maison(rng, centre, face, larg, prof, h, etage, avant, haie)
	if rng.randf() < 0.5:
		_arbre(racine, centre + Vector3(rng.randf_range(-4, 4), 0, -face * (prof * 0.5 + 6.0)), rng, rng.randf_range(0.7, 1.0))


# ---------------------------------------------------------------------------
# Quartiers
# ---------------------------------------------------------------------------

static func _grands_ensembles(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var t1 := Color(0.95, 0.93, 0.9)
	var t2 := Color(0.9, 0.9, 0.95)
	_tour(racine, Vector3(-290, 0, -205), 18, 18, 39, t1)
	_tour(racine, Vector3(-235, 0, -255), 16, 16, 33, t2)
	_tour(racine, Vector3(-230, 0, -395), 16, 16, 30, t1)
	_tour(racine, Vector3(-160, 0, -365), 18, 18, 42, t2)
	_tour(racine, Vector3(-90, 0, -335), 16, 16, 36, t1)
	# Barres
	_tour(racine, Vector3(-125, 0, -205), 80, 13, 15, Color(0.97, 0.94, 0.88))
	_tour(racine, Vector3(-275, 0, -365), 13, 70, 18, Color(0.93, 0.95, 0.97))
	# Parkings au pied des immeubles
	_parking(racine, Rect2(-175, -188, 100, 16), rng, 0.6)
	_parking(racine, Rect2(-312, -180, 40, 16), rng, 0.5)
	_parking(racine, Rect2(-255, -330, 40, 16), rng, 0.5)
	# City-stade et gymnase
	Geo.boite(racine, Vector3(40, 0.06, 22), Vector3(-160, 0.07, -270), Color(0.25, 0.5, 0.3), false)
	for xx in [-179.0, -141.0]:
		Geo.boite(racine, Vector3(0.2, 2.0, 5.0), Vector3(xx, 1.0, -270), Color(0.95, 0.95, 0.95), false)
	Geo.boite(racine, Vector3(0.15, 0.02, 22), Vector3(-160, 0.11, -270), Color(0.95, 0.95, 0.95), false)
	Geo.boite_mat(racine, Vector3(40, 9, 25), Vector3(-110, 4.5, -405), Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.55, 0.62, 0.7)))
	Geo.texte(racine, "GYMNASE", Vector3(-110, 7, -392.2), 80, Color(1, 1, 1), false)
	# Espaces verts
	for i in 40:
		var p := Vector3(rng.randf_range(-315, -60), 0, rng.randf_range(-425, -160))
		if _libre(p, 12.0, [Vector2(-290, -205), Vector2(-235, -255), Vector2(-230, -395), Vector2(-160, -365), Vector2(-90, -335)]) and not _dans_rects(p, [Rect2(-168, -215, 86, 50), Rect2(-285, -402, 22, 76), Rect2(-182, -284, 44, 28), Rect2(-132, -420, 44, 30), Rect2(-318, -276, 56, 22), Rect2(-246, -198, 28, 28), Rect2(-128, -282, 66, 56), Rect2(-262, -372, 44, 34), Rect2(-324, -334, 28, 28), Rect2(-180, -332, 60, 22), Rect2(-100, -390, 40, 22)]):
			_arbre(racine, p, rng, rng.randf_range(0.8, 1.2))


static func _libre(p: Vector3, rayon: float, centres: Array) -> bool:
	for c in centres:
		if Vector2(p.x, p.z).distance_to(c) < rayon + 10.0:
			return false
	return true


static func _dans_rects(p: Vector3, rects: Array) -> bool:
	for r in rects:
		var rr: Rect2 = r
		if rr.has_point(Vector2(p.x, p.z)):
			return true
	return false


static func _pavillons_nord(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var blocs: Array = [[-40.0, 245.0], [255.0, 345.0], [355.0, 445.0], [455.0, 615.0]]
	# [z du bord de parcelle, sens vers la rue]
	var rangees: Array = [[-157.0, 1.0], [-293.0, -1.0], [-307.0, 1.0], [-423.0, -1.0]]
	for b in blocs:
		for r in rangees:
			var x: float = b[0] + 9.0
			while x < b[1] - 8.0:
				_maison(racine, Vector3(x, 0, r[0]), r[1], rng)
				x += rng.randf_range(15.0, 19.0)
	# Rues de lotissement au cœur des îlots, bordées de maisons des deux côtés,
	# et haies de fond de jardin entre les rangées.
	var asph: Material = Tex.mat_asphalte()
	for b in blocs:
		var x0: float = b[0]
		var x1: float = b[1]
		for zl in [-225.0, -365.0]:
			Geo.boite_mat(racine, Vector3(x1 - x0 + 10.0, 0.05, 7.0), Vector3((x0 + x1) * 0.5, 0.055, zl), asph, false)
			# Trottoirs, réverbères et voitures garées le long de la rue de lotissement
			for cote2 in [-1.0, 1.0]:
				Lot.boite_c(Vector3(x1 - x0, 0.12, 1.6), Vector3((x0 + x1) * 0.5, 0.06, zl + cote2 * 4.3), Color(0.72, 0.71, 0.68))
			var xr: float = x0 + 12.0
			while xr < x1 - 5.0:
				Details.lampadaire(Vector3(xr, 0, zl - 4.6), 0.0)
				xr += 32.0
			var xv: float = x0 + rng.randf_range(10.0, 30.0)
			while xv < x1 - 8.0:
				_voiture(racine, Vector3(xv, 0, zl + 2.3), COULEURS_VOITURES[rng.randi() % COULEURS_VOITURES.size()], PI * 0.5)
				xv += rng.randf_range(25.0, 60.0)
			for cote in [-1.0, 1.0]:
				var x: float = x0 + 10.0
				while x < x1 - 9.0:
					_maison(racine, Vector3(x, 0, zl + cote * 4.0), -cote, rng)
					x += rng.randf_range(15.0, 19.0)
		for zh in [-190.0, -260.0, -333.0, -397.0]:
			Geo.boite_mat(racine, Vector3(x1 - x0 - 4.0, 1.6, 0.9), Vector3((x0 + x1) * 0.5, 0.8, zh), Tex.plaque("herbe", Tex.herbe(), 2.0, 2.0, Color(0.45, 0.7, 0.35)), false)
			# Quelques arbres fruitiers dans les jardins
			var xa: float = x0 + rng.randf_range(5.0, 20.0)
			while xa < x1 - 5.0:
				_arbre(racine, Vector3(xa, 0, zh + rng.randf_range(-7.0, 7.0)), rng, rng.randf_range(0.7, 1.1))
				xa += rng.randf_range(14.0, 30.0)


static func _zone_activites(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var bard_bleu: Material = Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.6, 0.68, 0.78))
	var bard_blanc: Material = Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.95, 0.95, 0.95))
	var bard_vert: Material = Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.55, 0.68, 0.6))
	# Entrepôt logistique avec quais et semi-remorques
	Geo.boite_mat(racine, Vector3(90, 12, 55), Vector3(390, 6, -85), bard_bleu)
	for k in 8:
		var qx: float = 352.0 + k * 10.5
		Geo.boite(racine, Vector3(3.2, 3.5, 0.3), Vector3(qx, 1.75, -57.4), Color(0.2, 0.2, 0.22), false)
		if k % 2 == 0:
			Geo.boite(racine, Vector3(2.5, 3.6, 13.0), Vector3(qx, 2.2, -50.0), Color(0.92, 0.92, 0.9), false)
			Geo.boite(racine, Vector3(2.5, 3.0, 2.4), Vector3(qx, 1.9, -42.2), Color(0.2, 0.3, 0.55), false)
	Geo.texte(racine, "LOGISTIQUE DU CHER", Vector3(390, 13.5, -57), 140, Color(0.15, 0.25, 0.5), false)
	# Hypermarché et son grand parking
	Geo.boite_mat(racine, Vector3(110, 9, 60), Vector3(555, 4.5, -100), bard_blanc)
	Geo.boite_mat(racine, Vector3(24, 4, 0.3), Vector3(555, 2.0, -69.8), Tex.vitre(), false)
	Geo.boite(racine, Vector3(112, 1.2, 2), Vector3(555, 9.4, -69), Color(0.85, 0.2, 0.15), false)
	Geo.texte(racine, "HYPERMARCHÉ", Vector3(555, 11.5, -69), 220, Color(0.85, 0.2, 0.15), false)
	_parking(racine, Rect2(470, -62, 170, 16), rng, 0.55)
	_parking(racine, Rect2(470, -40, 170, 16), rng, 0.45)
	# Concessionnaire et silos
	Geo.boite_mat(racine, Vector3(50, 7, 30), Vector3(375, 3.5, 45), bard_vert)
	Geo.boite_mat(racine, Vector3(30, 4, 0.3), Vector3(375, 2.0, 29.8), Tex.vitre(), false)
	_parking(racine, Rect2(345, 12, 60, 14), rng, 0.8)
	for k in 4:
		var s: MeshInstance3D = Geo.cylindre(racine, 4.0, 26.0, Vector3(415 + (k % 2) * 9.0, 13.0, 80 + int(k / 2) * 9.0), Color(0.78, 0.78, 0.8))
		s.material_override = Tex.carrosserie(Color(0.75, 0.76, 0.78))
	# Usine : halls, cheminée, cuves
	Geo.boite_mat(racine, Vector3(80, 14, 40), Vector3(525, 7, 60), bard_bleu)
	Geo.boite_mat(racine, Vector3(40, 10, 30), Vector3(605, 5, 40), bard_blanc)
	for k in 6:
		var bande := Color(0.85, 0.1, 0.1) if k % 2 == 0 else Color(0.95, 0.95, 0.95)
		Geo.cylindre(racine, 1.6, 7.5, Vector3(610, 3.75 + k * 7.5, 92), bande)
	for k in 3:
		Geo.cylindre(racine, 3.0, 8.0, Vector3(480 + k * 8.0, 4.0, 100), Color(0.85, 0.85, 0.82))
	# Toitures techniques : centrales de traitement d'air, lanterneaux, édicules
	for bat in [[Vector3(390, 0, -85), 90.0, 55.0, 12.0], [Vector3(555, 0, -100), 110.0, 60.0, 9.0], [Vector3(375, 0, 45), 50.0, 30.0, 7.0], [Vector3(525, 0, 60), 80.0, 40.0, 14.0], [Vector3(605, 0, 40), 40.0, 30.0, 10.0]]:
		_toiture(bat[0], bat[1], bat[2], bat[3], rng)
	# Clôture de l'usine avec portail, totems et éclairage des parkings
	var grillage := Lot.couleur(Color(0.3, 0.42, 0.32))
	Lot.boite(Vector3(100, 2.0, 0.08), Vector3(525, 1.0, 34), grillage)
	Lot.boite(Vector3(100, 2.0, 0.08), Vector3(525, 1.0, 112), grillage)
	Lot.boite(Vector3(0.08, 2.0, 78), Vector3(475, 1.0, 73), grillage)
	Lot.boite(Vector3(0.08, 2.0, 78), Vector3(575, 1.0, 73), grillage)
	Lot.boite_c(Vector3(0.6, 1.2, 0.6), Vector3(530, 0.6, 31), Color(0.85, 0.85, 0.8))
	Lot.boite_c(Vector3(6, 0.15, 0.15), Vector3(534, 1.0, 31), Color(0.9, 0.15, 0.1))
	for totem in [[Vector3(470, 0, -15), "HYPERMARCHÉ", Color(0.85, 0.2, 0.15)], [Vector3(340, 0, -15), "ZA DES ORMEAUX", Color(0.2, 0.35, 0.6)]]:
		var tp: Vector3 = totem[0]
		Lot.boite_c(Vector3(2.2, 7.0, 0.6), tp + Vector3(0, 3.5, 0), totem[2])
		var tl := Geo.texte(racine, totem[1], tp + Vector3(0, 6.0, 0.32), 40, Color(1, 1, 1), false)
		tl.basis = Basis(Vector3.FORWARD, PI * 0.5)
	var xl := 480.0
	while xl < 640.0:
		Lot.cylindre(0.12, 9.0, Vector3(xl, 4.5, -46), Lot.couleur(Color(0.5, 0.52, 0.55)))
		Lot.boite(Vector3(1.4, 0.2, 0.6), Vector3(xl, 9.0, -46), Lot.couleur(Color(1.0, 0.95, 0.8), 1.2))
		# Chariots et caddies regroupés
		Lot.boite_c(Vector3(2.5, 1.1, 1.0), Vector3(xl + 10, 0.55, -46), Color(0.7, 0.72, 0.75))
		xl += 40.0
	# Camions en attente sur la voirie interne
	for k in 3:
		_camion(Vector3(345 + k * 14.0, 0, -30), Basis(Vector3.UP, PI * 0.5))


static func _toiture(c: Vector3, l: float, p: float, h: float, rng: RandomNumberGenerator) -> void:
	var gris := Lot.couleur(Color(0.7, 0.72, 0.73))
	# Acrotère
	for cote in [-1.0, 1.0]:
		Lot.boite(Vector3(l + 0.4, 0.8, 0.3), c + Vector3(0, h + 0.4, cote * p * 0.5), gris)
		Lot.boite(Vector3(0.3, 0.8, p + 0.4), c + Vector3(cote * l * 0.5, h + 0.4, 0), gris)
	# Lanterneaux (bandes vitrées)
	var nb := int(l / 12.0)
	for k in nb:
		Lot.boite(Vector3(2.0, 0.6, p * 0.7), c + Vector3(-l * 0.5 + (k + 0.5) * l / nb, h + 0.3, 0), Tex.vitre())
	# Centrales de traitement d'air et gaines
	for k in int(l * p / 900.0) + 1:
		var u := c + Vector3(rng.randf_range(-l * 0.4, l * 0.4), h, rng.randf_range(-p * 0.4, p * 0.4))
		Lot.boite_c(Vector3(4.0, 1.8, 2.2), u + Vector3(0, 0.9, 0), Color(0.78, 0.8, 0.8))
		Lot.cylindre(0.7, 0.3, u + Vector3(-1.0, 1.95, 0), Lot.couleur(Color(0.3, 0.3, 0.32)))
		Lot.cylindre(0.7, 0.3, u + Vector3(1.0, 1.95, 0), Lot.couleur(Color(0.3, 0.3, 0.32)))
		Lot.boite_c(Vector3(0.8, 0.8, 6.0), u + Vector3(0, 0.4, 4.0), Color(0.65, 0.67, 0.68))


static func _camion(pos: Vector3, b: Basis) -> void:
	Lot.boite_c(Vector3(2.5, 3.0, 2.4), pos + b * Vector3(0, 1.9, -5.5), Color(0.85, 0.85, 0.85), b)
	Lot.boite(Vector3(2.3, 1.0, 0.05), pos + b * Vector3(0, 2.3, -6.72), Tex.vitre(), b)
	Lot.boite_c(Vector3(2.5, 3.4, 9.5), pos + b * Vector3(0, 2.2, 0.8), Color(0.95, 0.95, 0.95), b)
	Lot.boite_c(Vector3(2.52, 0.5, 9.5), pos + b * Vector3(0, 3.2, 0.8), Color(0.2, 0.35, 0.6), b)
	var roue := Basis(Vector3.FORWARD, PI * 0.5)
	for zz in [-5.5, 2.5, 4.0]:
		for xx in [-1.1, 1.1]:
			Lot.cylindre(0.5, 0.35, pos + b * Vector3(xx, 0.5, zz), Lot.couleur(Color(0.05, 0.05, 0.05)), b * roue)


static func _rocade(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var x0 := -420.0
	# Écran végétal le long de la rocade (pas sur le pont ni aux ronds-points)
	var za := -610.0
	while za < 610.0:
		var libre := not (za > 150.0 and za < 210.0)
		for zr in [-300.0, 0.0, 240.0]:
			if absf(za - zr) < 40.0:
				libre = false
		if libre:
			for cote in [-1.0, 1.0]:
				_arbre(racine, Vector3(x0 + cote * rng.randf_range(19.0, 26.0), 0, za + rng.randf_range(-4.0, 4.0)), rng, rng.randf_range(0.9, 1.3))
		za += rng.randf_range(12.0, 20.0)
	# Terre-plein central en béton (GBA), sauf aux carrefours
	for seg in [[-620.0, -330.0], [-270.0, -32.0], [32.0, 210.0], [270.0, 620.0]]:
		var a: float = seg[0]
		var b: float = seg[1]
		Geo.boite(racine, Vector3(0.6, 0.8, b - a), Vector3(x0, 0.4, (a + b) * 0.5), Color(0.75, 0.75, 0.72))
		# Glissières de sécurité sur les bords
		for cote in [-1.0, 1.0]:
			Geo.boite(racine, Vector3(0.15, 0.35, b - a), Vector3(x0 + cote * 11.3, 0.6, (a + b) * 0.5), Color(0.7, 0.72, 0.75), false)
		# Pointillés des voies
		var z := a + 2.0
		while z < b - 2.0:
			for cote in [-1.0, 1.0]:
				Geo.boite(racine, Vector3(0.18, 0.02, 3.0), Vector3(x0 + cote * 5.5, 0.085, z), Color(0.92, 0.92, 0.9), false)
			z += 12.0
		# Grands lampadaires
		var zl := a + 25.0
		while zl < b:
			Geo.cylindre(racine, 0.12, 11.0, Vector3(x0, 5.5, zl), Color(0.6, 0.62, 0.65))
			Geo.boite(racine, Vector3(6.0, 0.25, 0.4), Vector3(x0, 11.0, zl), Color(0.6, 0.62, 0.65), false)
			zl += 60.0
	# Ronds-points sur la rocade
	for zr in [0.0, -300.0, 240.0]:
		var anneau: MeshInstance3D = Geo.cylindre(racine, 27.0, 0.05, Vector3(x0, 0.058, zr), Color(0.2, 0.2, 0.21))
		anneau.material_override = Tex.mat_asphalte()
		var ilot: MeshInstance3D = Geo.cylindre(racine, 13.0, 0.5, Vector3(x0, 0.25, zr), Color(0.3, 0.45, 0.2))
		ilot.material_override = Tex.mat_herbe()
		Geo.cylindre(racine, 13.3, 0.3, Vector3(x0, 0.15, zr), Color(0.8, 0.8, 0.78))
		_arbre(racine, Vector3(x0, 0.5, zr), rng, 1.3)
	Geo.texte(racine, "ROCADE", Vector3(x0 + 14, 6, -60), 120, Color(1, 1, 1))


static func _bords_du_cher(racine: Node3D, rng: RandomNumberGenerator) -> void:
	# Promenades plantées sur les deux rives
	for zp in [152.0, 207.0]:
		Geo.boite_mat(racine, Vector3(1500, 0.05, 6), Vector3(100, 0.06, zp), Tex.mat_paves(), false)
		var x := -690.0
		while x < 880.0:
			if absf(x - 100.0) > 12.0 and absf(x + 420.0) > 18.0:
				_arbre(racine, Vector3(x, 0, zp + (2.5 if zp > 180.0 else -2.5)), rng, rng.randf_range(0.9, 1.3))
				if rng.randf() < 0.25:
					Geo.boite(racine, Vector3(1.8, 0.45, 0.6), Vector3(x + 6, 0.45, zp), Color(0.45, 0.32, 0.2), false)
			x += 16.0
	# Bateaux amarrés (toues de Loire)
	for bx in [-260.0, 20.0, 320.0]:
		var coque: Node3D = Geo.boite(racine, Vector3(12, 0.8, 2.6), Vector3(bx, 0.3, 163.5), Color(0.35, 0.25, 0.15), false)
		coque.name = "toue"
		Geo.boite(racine, Vector3(4, 1.4, 2.2), Vector3(bx + 2, 1.3, 163.5), Color(0.55, 0.42, 0.28), false)


static func _rive_sud(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var tuffeau: Material = Tex.plaque("tuffeau_uni", Tex.beton(), 3.0, 3.0, Color(0.95, 0.9, 0.78))
	# Église en tuffeau avec clocher et flèche d'ardoise
	Geo.boite_mat(racine, Vector3(14, 0.05, 50), Vector3(10, 0.07, 285), Tex.mat_paves(), false)
	Geo.boite_mat(racine, Vector3(13, 14, 34), Vector3(10, 7, 292), tuffeau)
	Geo.toit(racine, 13.6, 34.6, 7.0, Vector3(10, 14, 292), Tex.mat_ardoise(), false)
	Geo.boite_mat(racine, Vector3(8, 26, 8), Vector3(10, 13, 271), tuffeau)
	var fleche := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 5.6
	cm.height = 16.0
	cm.radial_segments = 4
	fleche.mesh = cm
	fleche.material_override = Tex.mat_ardoise()
	fleche.position = Vector3(10, 34, 271)
	fleche.rotation.y = PI * 0.25
	racine.add_child(fleche)
	Geo.boite(racine, Vector3(3, 5, 0.3), Vector3(10, 2.5, 266.9), Color(0.3, 0.2, 0.12), false)
	# Collège
	Geo.boite_mat(racine, Vector3(70, 10, 15), Vector3(265, 5, 330), tuffeau)
	Geo.boite_mat(racine, Vector3(15, 10, 40), Vector3(237, 5, 357), tuffeau)
	Geo.texte(racine, "COLLÈGE JEAN-MOULIN", Vector3(265, 8, 322.3), 90, Color(0.2, 0.2, 0.25), false)
	Geo.boite(racine, Vector3(50, 0.05, 30), Vector3(275, 0.07, 360), Color(0.55, 0.55, 0.55), false)
	# Parc avec étang
	var etang: MeshInstance3D = Geo.cylindre(racine, 22.0, 0.05, Vector3(-280, 0.07, 320), Color(0.2, 0.35, 0.45))
	etang.name = "etang"
	for i in 35:
		var p := Vector3(rng.randf_range(-400, -165), 0, rng.randf_range(255, 390))
		if Vector2(p.x, p.z).distance_to(Vector2(-280, 320)) > 26.0:
			_arbre(racine, p, rng, rng.randf_range(0.9, 1.4))
	Geo.boite_mat(racine, Vector3(4, 0.05, 140), Vector3(-200, 0.065, 320), Tex.mat_paves(), false)
	Geo.texte(racine, "Parc de la Rabière", Vector3(-280, 4, 250), 70, Color(0.9, 1, 0.9))
	# Pavillons de la rive sud
	var rangees: Array = [[247.0, -1.0, -140.0, 90.0], [247.0, -1.0, 360.0, 610.0], [393.0, 1.0, -140.0, 90.0], [393.0, 1.0, 110.0, 340.0], [407.0, -1.0, -140.0, 340.0]]
	for r in rangees:
		var x: float = r[2] + 9.0
		while x < r[3] - 8.0:
			if not (r[0] < 300.0 and x > -12.0 and x < 32.0):
				# Ici la rue est au nord de la parcelle quand le sens vaut -1 (z plus petit)
				_maison(racine, Vector3(x, 0, r[0]), -r[1], rng)
			x += rng.randf_range(15.0, 19.0)


static func _campagne(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var couleurs: Array = [Color(0.78, 0.68, 0.35), Color(0.45, 0.55, 0.25), Color(0.5, 0.4, 0.3), Color(0.6, 0.62, 0.3)]
	var z := -640.0
	while z < 640.0:
		var x := -880.0
		while x < -450.0:
			var l := rng.randf_range(90.0, 140.0)
			var p := rng.randf_range(80.0, 130.0)
			l = minf(l, -450.0 - x)
			if absf(z + p * 0.5 - 180.0) > 40.0:
				if rng.randf() < 0.25:
					# Vigne : rangs de ceps
					var zz := z + 3.0
					while zz < z + p - 3.0:
						Geo.boite(racine, Vector3(l - 6.0, 1.0, 0.6), Vector3(x + l * 0.5, 0.5, zz), Color(0.3, 0.42, 0.18), false)
						zz += 6.0
				else:
					Geo.boite(racine, Vector3(l - 2.0, 0.05, p - 2.0), Vector3(x + l * 0.5, 0.06, z + p * 0.5), couleurs[rng.randi() % couleurs.size()], false)
				# Haie bocagère
				Geo.boite(racine, Vector3(l, 2.5, 1.5), Vector3(x + l * 0.5, 1.25, z), Color(0.2, 0.33, 0.15), false)
			x += l
		z += rng.randf_range(80.0, 130.0)
	# Ferme : maison, grange, silo
	var tuffeau: Material = Tex.plaque("tuffeau_uni", Tex.beton(), 3.0, 3.0, Color(0.95, 0.9, 0.78))
	Geo.boite_mat(racine, Vector3(16, 6, 9), Vector3(-610, 3, -120), tuffeau)
	Geo.toit(racine, 16.6, 9.6, 4.0, Vector3(-610, 6, -120), Tex.mat_ardoise(), true)
	Geo.boite_mat(racine, Vector3(30, 9, 18), Vector3(-640, 4.5, -95), Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.55, 0.3, 0.22)))
	Geo.cylindre(racine, 3.0, 14.0, Vector3(-615, 7, -90), Color(0.8, 0.8, 0.8))
	Geo.boite(racine, Vector3(6, 0.05, 70), Vector3(-612, 0.06, -60), Color(0.55, 0.5, 0.42), false)


static func _panneaux(racine: Node3D) -> void:
	var noms: Array = [
		["Les Tilleuls", Vector3(-120, 9, -160)],
		["Les Vignes", Vector3(150, 9, -160)],
		["Zone d'activités des Ormeaux", Vector3(460, 9, -6)],
		["Rive sud", Vector3(100, 9, 225)],
		["Centre ancien", Vector3(-330, 9, -10)],
	]
	for n in noms:
		var l: Label3D = Geo.texte(racine, n[0], n[1], 110, Color(1, 0.95, 0.8))
		l.outline_size = 16
	# Panneau d'entrée d'agglomération (blanc bordé de rouge) près du rond-point
	var pos := Vector3(-398, 0, -12)
	Geo.cylindre(racine, 0.06, 2.4, pos + Vector3(-1.0, 1.2, 0), Color(0.6, 0.6, 0.6))
	Geo.cylindre(racine, 0.06, 2.4, pos + Vector3(1.0, 1.2, 0), Color(0.6, 0.6, 0.6))
	Geo.boite(racine, Vector3(2.8, 1.0, 0.08), pos + Vector3(0, 2.2, 0), Color(0.85, 0.1, 0.1), false)
	Geo.boite(racine, Vector3(2.6, 0.85, 0.1), pos + Vector3(0, 2.2, 0), Color(0.97, 0.97, 0.97), false)
	var t: Label3D = Geo.texte(racine, "JOUÉ-LÈS-TOURS", pos + Vector3(0, 2.2, -0.07), 40, Color(0.05, 0.05, 0.05), false)
	t.rotation.y = PI
	t.outline_size = 0


# ---------------------------------------------------------------------------
# Densification : nouveaux bâtiments aux Tilleuls et aux Ormeaux
# ---------------------------------------------------------------------------

static func _densifier_tilleuls(racine: Node3D, rng: RandomNumberGenerator) -> void:
	# Barres et tours supplémentaires
	_tour(racine, Vector3(-290, 0, -265), 45, 12, 15, Color(0.95, 0.9, 0.82))
	_tour(racine, Vector3(-232, 0, -185), 16, 16, 27, Color(0.9, 0.92, 0.95))
	_tour(racine, Vector3(-310, 0, -320), 16, 16, 24, Color(0.97, 0.95, 0.9))
	_tour(racine, Vector3(-150, 0, -322), 50, 12, 12, Color(0.93, 0.88, 0.8))
	_tour(racine, Vector3(-80, 0, -380), 30, 12, 15, Color(0.9, 0.9, 0.88))
	_parking(racine, Rect2(-312, -255, 44, 14), rng, 0.6)
	_parking(racine, Rect2(-175, -310, 50, 14), rng, 0.5)
	# Centre commercial de quartier : galerie vitrée, enseignes, parking
	var c := Vector3(-95, 0, -262)
	var bard: Material = Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.82, 0.8, 0.76))
	Geo.boite_mat(racine, Vector3(50, 6.5, 24), c + Vector3(0, 3.25, 0), bard)
	_toiture(c, 50.0, 24.0, 6.5, rng)
	Lot.boite(Vector3(46, 3.2, 0.15), c + Vector3(0, 1.7, 12.05), Tex.vitrage(1))
	Lot.boite_c(Vector3(50.5, 0.4, 3.0), c + Vector3(0, 3.6, 13.4), Color(0.25, 0.3, 0.38))
	for k in 9:
		Lot.boite_c(Vector3(0.2, 3.4, 0.2), c + Vector3(-22 + k * 5.5, 1.7, 14.7), Color(0.6, 0.62, 0.65))
	var enseignes: Array = [["SUPÉRETTE", Color(0.85, 0.35, 0.1)], ["PHARMACIE", Color(0.1, 0.6, 0.3)], ["BOULANGERIE", Color(0.55, 0.32, 0.15)], ["LA POSTE", Color(0.95, 0.75, 0.1)], ["KEBAB", Color(0.7, 0.12, 0.1)]]
	for k in enseignes.size():
		var e: Array = enseignes[k]
		var px: float = -20.0 + k * 10.0
		Lot.boite_c(Vector3(8.0, 1.2, 0.2), c + Vector3(px, 5.3, 12.15), e[1])
		var t := Geo.texte(racine, e[0], c + Vector3(px, 5.3, 12.3), 60, Color(1, 1, 1), false)
		t.outline_size = 0
	Geo.texte(racine, "CENTRE COMMERCIAL DES TILLEULS", c + Vector3(0, 8.2, 12.2), 110, Color(0.25, 0.3, 0.4), false)
	_parking(racine, Rect2(-120, -246, 50, 16), rng, 0.65)
	# Groupe scolaire : bâtiment en L, préau, cour avec arbres et clôture
	var e2 := Vector3(-240, 0, -355)
	var crepi := Tex.plaque("crepi", Tex.crepi(), 3.0, 2.8, Color(0.98, 0.93, 0.82))
	Geo.boite_mat(racine, Vector3(30, 7, 10), e2 + Vector3(0, 3.5, -5), crepi)
	Geo.boite_mat(racine, Vector3(10, 7, 14), e2 + Vector3(-10, 3.5, 7), crepi)
	Geo.boite(racine, Vector3(30.5, 0.5, 10.5), e2 + Vector3(0, 7.25, -5), Color(0.55, 0.3, 0.2), false)
	Geo.boite(racine, Vector3(10.5, 0.5, 14.5), e2 + Vector3(-10, 7.25, 7), Color(0.55, 0.3, 0.2), false)
	Geo.texte(racine, "GROUPE SCOLAIRE DES TILLEULS", e2 + Vector3(0, 5.6, 0.1), 60, Color(0.2, 0.3, 0.5), false)
	Lot.boite_c(Vector3(14, 0.3, 8), e2 + Vector3(5, 3.2, 6), Color(0.6, 0.62, 0.65))
	for k in 4:
		Lot.cylindre(0.12, 3.1, e2 + Vector3(-1.5 + k * 4.3, 1.55, 9.6), Lot.couleur(Color(0.4, 0.45, 0.6)))
	Lot.boite_c(Vector3(30, 0.03, 16), e2 + Vector3(5, 0.08, 8), Color(0.45, 0.45, 0.47))
	for k in 3:
		Details.arbre(e2 + Vector3(-2 + k * 8.0, 0, 13.0), 0.9, rng)
	Lot.boite_c(Vector3(34, 1.8, 0.06), e2 + Vector3(2, 0.9, 16.5), Color(0.3, 0.45, 0.35))


static func _densifier_ormeaux(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var bard_gris: Material = Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.72, 0.74, 0.76))
	var bard_sable: Material = Tex.plaque("bardage", Tex.bardage(), 1.0, 1.0, Color(0.85, 0.8, 0.68))
	# Village d'artisans : cellules avec portes sectionnelles et enseignes
	var metiers: Array = ["MENUISERIE", "CARROSSERIE", "PLOMBERIE", "IMPRIMERIE"]
	for k in 4:
		var c := Vector3(352 + k * 24.0, 0, 128)
		Geo.boite_mat(racine, Vector3(22, 8, 18), c + Vector3(0, 4, 0), bard_gris if k % 2 == 0 else bard_sable)
		_toiture(c, 22.0, 18.0, 8.0, rng)
		for d in 2:
			Lot.boite_c(Vector3(4.2, 4.5, 0.15), c + Vector3(-5 + d * 8.0, 2.25, -9.05), Color(0.55, 0.57, 0.6))
			for r in 9:
				Lot.boite_c(Vector3(4.2, 0.04, 0.17), c + Vector3(-5 + d * 8.0, 0.5 * r + 0.25, -9.06), Color(0.45, 0.47, 0.5))
		Lot.boite(Vector3(1.0, 2.2, 0.12), c + Vector3(8.5, 1.1, -9.05), Tex.vitrage(2))
		var t := Geo.texte(racine, metiers[k], c + Vector3(0, 6.3, -9.2), 70, Color(0.15, 0.2, 0.3), false)
		t.rotation.y = PI
		t.outline_size = 0
		VoitureModele.garer(Lot, "utilitaire", COULEURS_VOITURES[(k * 2) % COULEURS_VOITURES.size()], c + Vector3(3, 0, -13), Basis(Vector3.UP, PI * 0.5))
	# Immeuble de bureaux vitré
	var b := Vector3(625, 0, 128)
	Geo.boite_mat(racine, Vector3(36, 12, 20), b + Vector3(0, 6, 0), Tex.mat_beton(Color(0.85, 0.85, 0.85)))
	for e in 3:
		for face in [-1.0, 1.0]:
			Lot.boite(Vector3(35, 2.6, 0.1), b + Vector3(0, 1.8 + e * 4.0, face * 10.05), Tex.vitrage(e))
			Lot.boite_c(Vector3(36.2, 0.5, 0.3), b + Vector3(0, 3.7 + e * 4.0, face * 10.1), Color(0.75, 0.76, 0.78))
	_toiture(b, 36.0, 20.0, 12.0, rng)
	var tb := Geo.texte(racine, "PÔLE ENTREPRISES", b + Vector3(0, 13.5, -10.2), 90, Color(0.2, 0.3, 0.5), false)
	tb.rotation.y = PI
	_parking(racine, Rect2(600, 100, 50, 14), rng, 0.6)
	# Station-service : auvent, pompes, boutique
	var st := Vector3(395, 0, -133)
	Lot.boite_c(Vector3(22, 0.8, 12), st + Vector3(0, 5.2, 0), Color(0.95, 0.95, 0.95))
	Lot.boite_c(Vector3(22.1, 0.35, 12.1), st + Vector3(0, 5.0, 0), Color(0.15, 0.45, 0.25))
	Lot.boite(Vector3(20, 0.05, 10), st + Vector3(0, 4.78, 0), Tex.emissif(Color(1.0, 0.98, 0.92), 0.8))
	for k in 3:
		Lot.boite_c(Vector3(0.4, 4.8, 0.4), st + Vector3(-7 + k * 7.0, 2.4, 0), Color(0.85, 0.85, 0.85))
		Lot.boite_c(Vector3(1.0, 1.8, 0.6), st + Vector3(-7 + k * 7.0, 0.9, 1.5), Color(0.92, 0.92, 0.9))
		Lot.boite_c(Vector3(1.02, 0.4, 0.62), st + Vector3(-7 + k * 7.0, 1.5, 1.5), Color(0.15, 0.45, 0.25))
		Lot.boite_c(Vector3(2.4, 0.2, 1.4), st + Vector3(-7 + k * 7.0, 0.1, 1.5), Color(0.7, 0.7, 0.7))
	Lot.boite_c(Vector3(24, 0.03, 16), st + Vector3(0, 0.08, 0), Color(0.3, 0.3, 0.32))
	Geo.boite_mat(racine, Vector3(12, 3.5, 8), st + Vector3(0, 1.75, -11), Tex.mat_beton(Color(0.9, 0.9, 0.88)))
	Lot.boite(Vector3(8, 2.4, 0.1), st + Vector3(0, 1.3, -6.95), Tex.vitrage(0))
	Geo.texte(racine, "STATION", st + Vector3(0, 5.2, 6.1), 80, Color(1, 1, 1), false)
	VoitureModele.garer(Lot, "berline", COULEURS_VOITURES[1], st + Vector3(-3.5, 0, 1.5), Basis(Vector3.UP, PI * 0.5))
