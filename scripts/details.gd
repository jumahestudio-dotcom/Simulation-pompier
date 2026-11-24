## Les détails qui habillent la ville : devantures de commerces, portes, balcons, lucarnes,
## descentes d'eau, mobilier urbain (feux, abribus, potelets, poubelles, bancs…).
## Tout passe par lot.gd pour rester léger.
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")
const Lot = preload("res://scripts/lot.gd")
const Modeles = preload("res://scripts/modeles3d.gd")

## Commerces fictifs : [enseigne, couleur de devanture, couleur du store]
const COMMERCES: Array = [
	["BOULANGERIE", Color(0.45, 0.25, 0.15), Color(0.85, 0.75, 0.55)],
	["PHARMACIE", Color(0.15, 0.45, 0.3), Color(0.2, 0.6, 0.35)],
	["TABAC PRESSE", Color(0.5, 0.1, 0.1), Color(0.75, 0.15, 0.15)],
	["CAFÉ DES HALLES", Color(0.12, 0.2, 0.15), Color(0.6, 0.12, 0.12)],
	["FLEURISTE", Color(0.25, 0.4, 0.25), Color(0.9, 0.9, 0.85)],
	["BOUCHERIE", Color(0.55, 0.12, 0.12), Color(0.85, 0.25, 0.25)],
	["LIBRAIRIE", Color(0.15, 0.2, 0.35), Color(0.2, 0.3, 0.5)],
	["COIFFURE", Color(0.1, 0.1, 0.1), Color(0.2, 0.2, 0.2)],
	["OPTICIEN", Color(0.85, 0.85, 0.82), Color(0.3, 0.3, 0.35)],
	["BANQUE", Color(0.15, 0.25, 0.45), Color(0.15, 0.25, 0.45)],
	["AGENCE IMMOBILIÈRE", Color(0.2, 0.2, 0.25), Color(0.85, 0.55, 0.15)],
	["PRESSING", Color(0.2, 0.35, 0.55), Color(0.3, 0.55, 0.8)],
	["PRIMEUR", Color(0.25, 0.35, 0.15), Color(0.35, 0.55, 0.2)],
	["CRÊPERIE", Color(0.3, 0.2, 0.35), Color(0.15, 0.25, 0.55)],
	["SUPÉRETTE", Color(0.75, 0.75, 0.75), Color(0.9, 0.45, 0.1)],
	["BRASSERIE", Color(0.12, 0.12, 0.12), Color(0.15, 0.3, 0.2)],
]

const PIERRE := Color(0.9, 0.87, 0.78)
const FER := Color(0.12, 0.13, 0.14)
const ZINC := Color(0.55, 0.57, 0.58)


static func _mat_pierre() -> Material:
	return Tex.plaque("soubassement", Tex.beton(), 2.0, 2.0, Color(0.93, 0.89, 0.78))


## Repère d'une façade : t le long de la façade, n vers la rue (vers l'extérieur).
static func _base(n: Vector3) -> Basis:
	var t := Vector3.UP.cross(n)
	return Basis(t, Vector3.UP, n)


## Point de la façade : a le long, y en hauteur, d vers la rue.
static func _p(pied: Vector3, b: Basis, a: float, y: float, d: float) -> Vector3:
	return pied + b.x * a + Vector3.UP * y + b.z * d


# ---------------------------------------------------------------------------
# Immeubles du centre ancien
# ---------------------------------------------------------------------------

## Immeuble ancien complet du centre : corps de bâtiment, corniche, toit, cheminées, façade sur rue
## (pierre de taille, enduit ou brique) avec fenêtres en relief, et façade arrière sur cour.
## pied : milieu du bas de la façade sur rue ; n : direction de la rue (axe x ou z).
## angles : côtés (-1 : début de la façade, +1 : fin) qui donnent sur une rue transversale et reçoivent des fenêtres.
static func immeuble_ancien(racine: Node3D, rng: RandomNumberGenerator, pied: Vector3, n: Vector3, largeur: float, h_et: float, profondeur: float, commerce: bool, angles: Array = []) -> void:
	var tirage := rng.randf()
	var style := "pierre" if tirage < 0.55 else ("enduit" if tirage < 0.9 else "brique")
	var mat_mur: Material
	if style == "pierre":
		mat_mur = Tex.mat_pierre_taille(TUFFEAUX[rng.randi() % TUFFEAUX.size()])
	elif style == "enduit":
		mat_mur = Tex.mat_enduit(ENDUITS[rng.randi() % ENDUITS.size()])
	else:
		mat_mur = Tex.mat_brique()
	var selon_z := absf(n.x) > 0.5
	var centre := pied - n * (profondeur * 0.5)
	var taille := Vector3(profondeur, h_et, largeur - 0.4) if selon_z else Vector3(largeur - 0.4, h_et, profondeur)
	Geo.boite_mat(racine, taille, centre + Vector3(0, h_et * 0.5, 0), mat_mur)
	# Toit : ardoise le plus souvent, parfois zinc ; pente variable
	var mat_toit: Material = Tex.mat_ardoise() if rng.randf() < 0.8 else Tex.mat_zinc()
	var h_toit := rng.randf_range(3.0, 4.8)
	if selon_z:
		Geo.toit(racine, profondeur + 0.4, largeur - 0.2, h_toit, centre + Vector3(0, h_et + 0.35, 0), mat_toit, false)
	else:
		Geo.toit(racine, largeur - 0.2, profondeur + 0.4, h_toit, centre + Vector3(0, h_et + 0.35, 0), mat_toit, true)
	# Corniche moulurée (deux ressauts) tout autour du toit
	var b := _base(n)
	var l := largeur - 0.4
	var pierre_claire := Lot.couleur(Color(0.93, 0.91, 0.85))
	Lot.boite(Vector3(l + 0.3, 0.22, profondeur + 0.3), centre + Vector3(0, h_et + 0.24, 0), pierre_claire, b)
	Lot.boite(Vector3(l + 0.14, 0.16, profondeur + 0.14), centre + Vector3(0, h_et + 0.05, 0), pierre_claire, b)
	# Cheminées en brique sur le faîtage, avec leurs pots
	var nb_ch := rng.randi_range(1, 3)
	for k in nb_ch:
		var a: float = -l * 0.5 + (k + 0.5) * l / nb_ch + rng.randf_range(-0.8, 0.8)
		var pc := centre + b.x * a + Vector3(0, h_et + h_toit * 0.75, 0) - n * rng.randf_range(-0.6, 0.6)
		Lot.boite(Vector3(0.95, h_toit * 0.5 + 1.6, 0.6), pc + Vector3(0, h_toit * 0.25 + 0.4, 0), Tex.mat_brique(), b)
		Lot.boite(Vector3(1.05, 0.12, 0.7), pc + Vector3(0, h_toit * 0.5 + 1.25, 0), pierre_claire, b)
		for pk in 2:
			Lot.cylindre(0.09, 0.35, pc + b.x * (-0.22 + pk * 0.44) + Vector3(0, h_toit * 0.5 + 1.48, 0), Lot.couleur(Color(0.62, 0.32, 0.2)))
	immeuble_centre(racine, rng, pied, n, largeur, h_et, profondeur, commerce)
	var volets: Color = VOLETS[rng.randi() % VOLETS.size()]
	var avec_volets := rng.randf() < 0.75
	_fenetres(rng, pied, b, l, h_et, style, volets, avec_volets, true)
	# Façades latérales à l'angle d'une rue
	for c in angles:
		var cote: float = c
		var pied_l := pied - n * (profondeur * 0.5) + b.x * (cote * l * 0.5)
		_fenetres(rng, pied_l, _base(b.x * cote), profondeur, h_et, style, volets, avec_volets, true)
	# Façade arrière sur cour : fenêtres plus simples, sans volets
	var arriere := pied - n * profondeur
	_fenetres(rng, arriere, _base(-n), l, h_et, style, volets, false, false)
	for k in int(l / 4.5):
		if rng.randf() < 0.6:
			_lucarne(arriere, _base(-n), -l * 0.5 + (k + 0.5) * l / int(l / 4.5), h_et + 0.35)


## Fenêtres en relief sur tous les étages d'une façade.
static func _fenetres(rng: RandomNumberGenerator, pied: Vector3, b: Basis, l: float, h_et: float, style: String, volets: Color, avec_volets: bool, rue: bool) -> void:
	var n_et := maxi(1, int((h_et - 3.5) / 2.8))
	var pas := (h_et - 3.5) / n_et
	var n_tr := maxi(1, int(l / 3.2))
	var cadre := Lot.couleur(Color(0.96, 0.96, 0.94))
	var pierre := Lot.couleur(Color(0.95, 0.93, 0.87) if style != "enduit" else Color(0.97, 0.96, 0.92))
	var mat_volet := Tex.mat_volet(volets)
	var w := minf(1.2, l / n_tr - 1.4)
	if w < 0.6:
		return
	for e in n_et:
		var f := 3.5 + e * pas
		# Bandeau d'étage en pierre (sauf enduit)
		if style != "enduit" and e > 0:
			Lot.boite(Vector3(l, 0.16, 0.08), _p(pied, b, 0, f, 0.04), pierre, b)
		var porte_fenetre := rue and e == 0 and pas > 2.6 and rng.randf() < 0.5
		var h := minf(2.3 if porte_fenetre else 1.75, pas * (0.8 if porte_fenetre else 0.62))
		var y0 := f + (0.12 if porte_fenetre else pas * 0.26)
		for t in n_tr:
			var a: float = -l * 0.5 + (t + 0.5) * l / n_tr
			if not rue and rng.randf() < 0.2:
				continue
			var yc := y0 + h * 0.5
			# Encadrement en saillie (4 pièces) : la vitre paraît en retrait
			Lot.boite(Vector3(0.18, h + 0.36, 0.14), _p(pied, b, a - w * 0.5 - 0.09, yc, 0.07), pierre, b)
			Lot.boite(Vector3(0.18, h + 0.36, 0.14), _p(pied, b, a + w * 0.5 + 0.09, yc, 0.07), pierre, b)
			Lot.boite(Vector3(w, 0.2, 0.14), _p(pied, b, a, y0 + h + 0.08, 0.07), pierre, b)
			if style == "pierre" and rue:
				Lot.boite(Vector3(0.24, 0.3, 0.17), _p(pied, b, a, y0 + h + 0.12, 0.085), pierre, b)
			# Appui saillant
			Lot.boite(Vector3(w + 0.5, 0.09, 0.26), _p(pied, b, a, y0 - 0.06, 0.13), pierre, b)
			# Dormant blanc, vitrage, petits bois
			Lot.boite(Vector3(w, h, 0.03), _p(pied, b, a, yc, 0.015), cadre, b)
			Lot.boite(Vector3(w - 0.12, h - 0.12, 0.03), _p(pied, b, a, yc, 0.03), Tex.vitrage(rng.randi() % 4), b)
			Lot.boite(Vector3(0.05, h - 0.1, 0.03), _p(pied, b, a, yc, 0.05), cadre, b)
			Lot.boite(Vector3(w - 0.1, 0.035, 0.03), _p(pied, b, a, y0 + h * 0.68, 0.05), cadre, b)
			if porte_fenetre:
				# Garde-corps en fer forgé devant la porte-fenêtre
				Lot.boite(Vector3(w + 0.1, 0.04, 0.04), _p(pied, b, a, y0 + 0.95, 0.2), Lot.couleur(FER), b)
				for k in 7:
					Lot.boite(Vector3(0.02, 0.9, 0.02), _p(pied, b, a - w * 0.5 + k * w / 6.0, y0 + 0.5, 0.2), Lot.couleur(FER), b)
			# Persiennes : ouvertes contre le mur, ou fermées
			if avec_volets:
				if rng.randf() < 0.14:
					Lot.boite(Vector3(w - 0.04, h - 0.04, 0.04), _p(pied, b, a, yc, 0.07), mat_volet, b)
				else:
					for c in [-1.0, 1.0]:
						Lot.boite(Vector3(w * 0.5, h, 0.04), _p(pied, b, a + c * (w * 0.75 + 0.2), yc, 0.04), mat_volet, b)


## Pierres de tuffeau, enduits et volets du centre ancien.
const TUFFEAUX: Array = [Color(1.0, 0.98, 0.93), Color(0.96, 0.93, 0.85), Color(0.98, 0.95, 0.88), Color(0.92, 0.89, 0.82)]
const ENDUITS: Array = [Color(0.96, 0.91, 0.79), Color(0.93, 0.82, 0.62), Color(0.95, 0.85, 0.78), Color(0.88, 0.88, 0.86), Color(0.98, 0.96, 0.9), Color(0.9, 0.86, 0.72)]
const VOLETS: Array = [Color(0.5, 0.58, 0.64), Color(0.55, 0.63, 0.55), Color(0.92, 0.92, 0.88), Color(0.72, 0.74, 0.74), Color(0.45, 0.2, 0.2), Color(0.38, 0.48, 0.58)]


## pied : milieu du bas de la façade côté rue ; n : direction de la rue.
static func immeuble_centre(racine: Node3D, rng: RandomNumberGenerator, pied: Vector3, n: Vector3, largeur: float, h_et: float, profondeur: float, commerce: bool) -> void:
	var b := _base(n)
	var pierre := _mat_pierre()
	var l := largeur - 0.4
	# Soubassement en pierre et bandeau au-dessus du rez-de-chaussée
	Lot.boite(Vector3(l, 3.2, 0.3), _p(pied, b, 0, 1.6, 0.15), pierre, b)
	Lot.boite(Vector3(l + 0.1, 0.28, 0.45), _p(pied, b, 0, 3.32, 0.2), Lot.couleur(PIERRE), b)
	# Chaînes d'angle (pierres plus claires aux coins)
	for cote in [-1.0, 1.0]:
		var y := 3.5
		while y < h_et - 0.5:
			Lot.boite(Vector3(0.6 if int(y) % 2 == 0 else 0.4, 0.45, 0.1), _p(pied, b, cote * (l * 0.5 - 0.3), y + 0.25, 0.05), Lot.couleur(Color(0.97, 0.95, 0.9)), b)
			y += 0.6
	if commerce:
		_devanture(racine, rng, pied, b, l)
	else:
		_entree_immeuble(rng, pied, b, l)
	# Balcon filant en fer forgé au premier étage, parfois au dernier
	var niveaux: Array = [3.62]
	if h_et >= 12.0 and rng.randf() < 0.5:
		niveaux.append(h_et - 2.0)
	for yb in niveaux:
		if rng.randf() < 0.75:
			_balcon(pied, b, rng.randf_range(-l * 0.1, l * 0.1), yb, minf(l * 0.8, rng.randf_range(3.0, l * 0.9)))
	# Descentes d'eau en zinc et gouttière
	for cote in [-1.0, 1.0]:
		Lot.boite(Vector3(0.12, h_et, 0.12), _p(pied, b, cote * (l * 0.5 - 0.15), h_et * 0.5, 0.12), Lot.couleur(ZINC), b)
	Lot.boite(Vector3(l, 0.18, 0.25), _p(pied, b, 0, h_et + 0.1, 0.2), Lot.couleur(ZINC), b)
	# Lucarnes dans l'ardoise
	var nb := int(l / 4.5)
	for k in nb:
		if rng.randf() < 0.8:
			var a: float = -l * 0.5 + (k + 0.5) * l / nb
			_lucarne(pied, b, a, h_et + 0.35)


static func _devanture(racine: Node3D, rng: RandomNumberGenerator, pied: Vector3, b: Basis, l: float) -> void:
	var c: Array = COMMERCES[rng.randi() % COMMERCES.size()]
	var bois: Color = c[1]
	var store: Color = c[2]
	var w := minf(l - 1.0, rng.randf_range(5.0, 9.0))
	# Coffrage de devanture en bois peint
	Lot.boite(Vector3(w + 0.6, 2.9, 0.25), _p(pied, b, 0, 1.45, 0.32), Lot.couleur(bois), b)
	# Vitrine éclairée et porte vitrée, avec quelques présentoirs derrière
	var vitrine := Lot.couleur(Color(0.42, 0.4, 0.36), 0.35)
	Lot.boite(Vector3(w - 1.6, 2.1, 0.08), _p(pied, b, -0.6, 1.35, 0.42), vitrine, b)
	Lot.boite(Vector3(w - 1.6, 2.1, 0.03), _p(pied, b, -0.6, 1.35, 0.47), Lot.couleur(Color(0.6, 0.7, 0.8, 0.22)), b)
	for k in 3:
		Lot.boite(Vector3((w - 2.0) / 3.0 - 0.3, 0.9, 0.04), _p(pied, b, -0.6 - (w - 1.6) * 0.33 + k * (w - 1.6) * 0.33, 0.8, 0.45), Lot.couleur(bois.lightened(0.35)), b)
	Lot.boite(Vector3(1.0, 2.3, 0.08), _p(pied, b, w * 0.5 - 0.6, 1.15, 0.46), Tex.vitre(), b)
	# Soubassement de vitrine
	Lot.boite(Vector3(w - 1.6, 0.3, 0.1), _p(pied, b, -0.6, 0.15, 0.47), Lot.couleur(bois.darkened(0.3)), b)
	# Bandeau d'enseigne
	Lot.boite(Vector3(w + 0.6, 0.55, 0.12), _p(pied, b, 0, 2.95, 0.5), Lot.couleur(bois.darkened(0.2)), b)
	var e := Geo.texte(racine, str(c[0]), _p(pied, b, 0, 2.95, 0.58), 34, Color(0.98, 0.95, 0.85), false)
	e.basis = b
	e.outline_size = 0
	# Store banne incliné, à rayures
	if rng.randf() < 0.7:
		var incl := Basis(b.x, deg_to_rad(18.0))
		var bs := incl * b
		var bandes := int(w / 0.5)
		for k in bandes:
			var cb: Color = store if k % 2 == 0 else Color(0.95, 0.94, 0.9)
			var a: float = -w * 0.5 + (k + 0.5) * w / bandes
			Lot.boite(Vector3(w / bandes, 0.04, 1.6), _p(pied, b, a, 2.55, 1.25), Lot.couleur(cb), bs)
		Lot.boite(Vector3(w, 0.25, 0.03), _p(pied, b, 0, 2.18, 2.03), Lot.couleur(store), b)
	# Croix verte des pharmacies, carotte des tabacs
	if c[0] == "PHARMACIE":
		var verte := Lot.couleur(Color(0.1, 0.9, 0.3), 2.5)
		Lot.boite(Vector3(0.9, 0.3, 0.1), _p(pied, b, -w * 0.5 - 0.6, 3.9, 0.9), verte, b)
		Lot.boite(Vector3(0.3, 0.9, 0.1), _p(pied, b, -w * 0.5 - 0.6, 3.9, 0.9), verte, b)
		Lot.boite(Vector3(0.06, 0.06, 0.6), _p(pied, b, -w * 0.5 - 0.6, 3.9, 0.5), Lot.couleur(FER), b)
	elif c[0] == "TABAC PRESSE":
		var rouge := Lot.couleur(Color(0.9, 0.15, 0.1), 1.5)
		Lot.boite(Vector3(0.25, 1.1, 0.5), _p(pied, b, -w * 0.5 - 0.6, 4.0, 0.5), rouge, b * Basis(Vector3.FORWARD, 0.0))
	# Étal sur le trottoir pour le primeur et le fleuriste, terrasse pour les cafés
	if c[0] == "PRIMEUR" or c[0] == "FLEURISTE":
		Lot.boite(Vector3(w * 0.6, 0.8, 0.9), _p(pied, b, -0.6, 0.4, 1.2), Lot.couleur(Color(0.5, 0.38, 0.25)), b)
		for k in 6:
			var cf: Color = [Color(0.85, 0.2, 0.15), Color(0.95, 0.75, 0.1), Color(0.3, 0.6, 0.2), Color(0.9, 0.5, 0.6)][k % 4]
			Lot.boite(Vector3(w * 0.08, 0.15, 0.7), _p(pied, b, -0.6 - w * 0.25 + k * w * 0.1, 0.88, 1.2), Lot.couleur(cf), b)
	elif c[0].begins_with("CAFÉ") or c[0] == "BRASSERIE" or c[0] == "CRÊPERIE":
		for k in 3:
			var a2: float = -w * 0.35 + k * w * 0.35
			Lot.cylindre(0.35, 0.04, _p(pied, b, a2, 0.75, 1.9), Lot.couleur(Color(0.75, 0.75, 0.72)))
			Lot.cylindre(0.04, 0.75, _p(pied, b, a2, 0.37, 1.9), Lot.couleur(FER))
			for cs in [-0.6, 0.6]:
				Lot.boite(Vector3(0.42, 0.06, 0.42), _p(pied, b, a2 + cs, 0.45, 1.9), Lot.couleur(Color(0.55, 0.35, 0.2)), b)
				Lot.boite(Vector3(0.06, 0.45, 0.42), _p(pied, b, a2 + cs * 1.35, 0.7, 1.9), Lot.couleur(Color(0.55, 0.35, 0.2)), b)


static func _entree_immeuble(rng: RandomNumberGenerator, pied: Vector3, b: Basis, l: float) -> void:
	var a := rng.randf_range(-l * 0.25, l * 0.25)
	var bois: Color = [Color(0.3, 0.2, 0.12), Color(0.15, 0.25, 0.4), Color(0.2, 0.3, 0.22), Color(0.45, 0.12, 0.12)][rng.randi() % 4]
	# Encadrement en pierre de taille et porte en bois à deux battants
	Lot.boite(Vector3(2.0, 3.0, 0.15), _p(pied, b, a, 1.5, 0.36), Lot.couleur(Color(0.97, 0.95, 0.9)), b)
	Lot.boite(Vector3(1.5, 2.6, 0.12), _p(pied, b, a, 1.3, 0.42), Lot.couleur(bois), b)
	Lot.boite(Vector3(0.04, 2.5, 0.05), _p(pied, b, a, 1.3, 0.49), Lot.couleur(bois.darkened(0.4)), b)
	Lot.boite(Vector3(1.3, 0.35, 0.05), _p(pied, b, a, 2.35, 0.5), Tex.vitre(), b)
	Lot.boite(Vector3(0.6, 0.05, 0.08), _p(pied, b, a + 0.5, 1.2, 0.5), Lot.couleur(Color(0.75, 0.65, 0.3)), b)
	# Fenêtres du rez-de-chaussée avec grilles
	for cote in [-1.0, 1.0]:
		var af: float = a + cote * 2.6
		if absf(af) > l * 0.5 - 1.0:
			continue
		Lot.boite(Vector3(1.2, 1.6, 0.06), _p(pied, b, af, 1.75, 0.33), Tex.vitre(), b)
		Lot.boite(Vector3(1.35, 0.1, 0.25), _p(pied, b, af, 0.95, 0.4), Lot.couleur(Color(0.97, 0.95, 0.9)), b)
		for k in 6:
			Lot.boite(Vector3(0.03, 1.6, 0.03), _p(pied, b, af - 0.5 + k * 0.2, 1.75, 0.42), Lot.couleur(FER), b)


static func _balcon(pied: Vector3, b: Basis, a: float, y: float, longueur: float) -> void:
	Lot.boite(Vector3(longueur, 0.15, 0.75), _p(pied, b, a, y, 0.37), Lot.couleur(Color(0.92, 0.9, 0.84)), b)
	Lot.boite(Vector3(longueur, 0.05, 0.05), _p(pied, b, a, y + 1.0, 0.72), Lot.couleur(FER), b)
	Lot.boite(Vector3(longueur, 0.04, 0.04), _p(pied, b, a, y + 0.15, 0.72), Lot.couleur(FER), b)
	var nb := int(longueur / 0.18)
	for k in nb + 1:
		Lot.boite(Vector3(0.025, 0.85, 0.025), _p(pied, b, a - longueur * 0.5 + k * longueur / nb, y + 0.57, 0.72), Lot.couleur(FER), b)
	for cote in [-1.0, 1.0]:
		Lot.boite(Vector3(0.04, 0.9, 0.7), _p(pied, b, a + cote * longueur * 0.5, y + 0.55, 0.37), Lot.couleur(FER), b)


static func _lucarne(pied: Vector3, b: Basis, a: float, y_toit: float) -> void:
	var pierre := Lot.couleur(Color(0.95, 0.92, 0.84))
	Lot.boite(Vector3(1.5, 1.9, 1.8), _p(pied, b, a, y_toit + 0.95, -1.3), pierre, b)
	Lot.boite(Vector3(0.9, 1.15, 0.06), _p(pied, b, a, y_toit + 0.95, -0.38), Tex.vitre(), b)
	Lot.boite(Vector3(1.0, 0.08, 0.1), _p(pied, b, a, y_toit + 0.38, -0.35), Lot.couleur(Color(0.97, 0.96, 0.92)), b)
	Lot.toit(1.8, 0.8, 2.0, _p(pied, b, a, y_toit + 1.9, -1.2), Tex.mat_ardoise(), b)


# ---------------------------------------------------------------------------
# Mobilier urbain du centre
# ---------------------------------------------------------------------------

static func mobilier_centre(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var potelet := Lot.couleur(Color(0.22, 0.18, 0.14))
	var vert := Lot.couleur(Color(0.15, 0.35, 0.22))
	var rues_ns: Array = [-200.0, -50.0, 100.0, 250.0]
	# Potelets au bord des trottoirs du boulevard
	var x := -318.0
	while x < 318.0:
		var pres_rue := false
		for xs in rues_ns:
			if absf(x - xs) < 9.0:
				pres_rue = true
		for zz in [-8.6, 8.6]:
			if pres_rue:
				continue
			if zz < 0.0 and x > -292.0 and x < -206.0:
				continue   # sortie des engins de la caserne
			if zz > 0.0 and x > 138.0 and x < 182.0:
				continue   # trottoir de la chute
			Lot.cylindre(0.07, 0.9, Vector3(x, 0.45, zz), potelet)
			Lot.sphere(0.09, Vector3(x, 0.92, zz), potelet)
		x += 3.0
	# Feux tricolores aux carrefours du boulevard
	for xs in rues_ns:
		for coin in [[-1.0, -1.0], [1.0, 1.0]]:
			_feu_tricolore(Vector3(xs + coin[0] * 6.5, 0, coin[1] * 9.0), coin[1] > 0.0)
		# Passages piétons sur la rue transversale
		for cote in [-1.0, 1.0]:
			for k in 4:
				Lot.boite_c(Vector3(2.0, 0.02, 0.5), Vector3(xs - 3.0 + k * 2.0, 0.085, cote * 13.0), Color(0.92, 0.92, 0.9))
			Lot.boite_c(Vector3(4.6, 0.02, 0.3), Vector3(xs + cote * 2.4, 0.085, cote * 15.0), Color(0.92, 0.92, 0.9))
	# Marquage axial des rues transversales du centre
	for xs in rues_ns:
		var z := -145.0
		while z < 115.0:
			if absf(z) > 18.0:
				Lot.boite_c(Vector3(0.15, 0.02, 3.0), Vector3(xs, 0.085, z), Color(0.9, 0.9, 0.88))
			z += 7.0
	# Abribus
	_abribus(racine, Vector3(-130, 0, -10.5), 1.0)
	_abribus(racine, Vector3(30, 0, 10.5), -1.0)
	_abribus(racine, Vector3(200, 0, -10.5), 1.0)
	# Poteaux incendie rouges (pack de mobilier) sur les trottoirs du boulevard
	for ph in [Vector3(-40, 0, -12.8), Vector3(120, 0, 12.8), Vector3(260, 0, -12.8), Vector3(-160, 0, 12.8)]:
		Modeles.poser(racine, Modeles.RUE, ph, 0.0, 1.0, Modeles.MOBILIER["poteau"], false)
	# Colonne d'affichage
	Lot.cylindre(0.75, 3.0, Vector3(41, 1.5, -11.5), vert)
	Lot.cylindre(0.8, 2.2, Vector3(41, 1.7, -11.5), Lot.couleur(Color(0.9, 0.85, 0.7)))
	Lot.sphere(0.85, Vector3(41, 3.05, -11.5), vert, 0.5)
	# Poubelles, bancs et arceaux à vélos le long du boulevard
	x = -300.0
	while x < 300.0:
		for zz in [-12.0, 12.0]:
			if zz < 0.0 and x > -292.0 and x < -206.0:
				continue
			var r := rng.randf()
			var p := Vector3(x + rng.randf_range(-3.0, 3.0), 0, zz)
			if r < 0.4:
				if Modeles.poser(racine, Modeles.RUE, p, 0.0, 1.0, Modeles.MOBILIER["poubelle"], false) == null:
					Lot.cylindre(0.05, 1.0, p + Vector3(0, 0.5, 0), vert)
					Lot.cylindre(0.28, 0.6, p + Vector3(0, 0.8, 0), Lot.couleur(Color(0.2, 0.5, 0.3)))
			elif r < 0.75:
				var mod: String = Modeles.MOBILIER["banc_bois"] if r < 0.6 else Modeles.MOBILIER["banc_metal"]
				if Modeles.poser(racine, Modeles.RUE, p, (0.0 if zz < 0.0 else PI) + Modeles.BANC_ROT, 1.0, mod, false) == null:
					_banc(p, 0.0 if zz < 0.0 else PI)
			elif r < 0.82 and Modeles.present(Modeles.RUE):
				Modeles.poser(racine, Modeles.RUE, p, 0.0, 1.0, Modeles.MOBILIER["jardiniere"], false)
			else:
				for k in 3:
					var arc := Basis(Vector3.UP, PI * 0.5)
					Lot.boite(Vector3(0.05, 0.8, 0.05), p + Vector3(k * 0.9 - 0.35, 0.4, 0), Lot.couleur(ZINC), arc)
					Lot.boite(Vector3(0.05, 0.8, 0.05), p + Vector3(k * 0.9 + 0.35, 0.4, 0), Lot.couleur(ZINC), arc)
					Lot.boite(Vector3(0.75, 0.05, 0.05), p + Vector3(k * 0.9, 0.8, 0), Lot.couleur(ZINC))
		x += 22.0
	# Plaques de rue bleues aux angles
	var noms := {-200.0: "rue du Lavoir", -50.0: "rue des Remparts", 100.0: "rue Rabelais", 250.0: "rue des Tanneurs"}
	for xs in rues_ns:
		var pl := Geo.texte(racine, str(noms[xs]), Vector3(xs - 9.2, 3.6, -21.0), 22, Color(1, 1, 1), false)
		pl.basis = Basis(Vector3.UP, -PI * 0.5)
		pl.outline_size = 0
		Lot.boite_c(Vector3(0.05, 0.4, 1.6), Vector3(xs - 9.12, 3.6, -21.0), Color(0.12, 0.25, 0.55))
	# Bouches d'égout et grilles
	x = -310.0
	while x < 310.0:
		for zz in [-6.6, 6.6]:
			Lot.boite_c(Vector3(0.9, 0.02, 0.5), Vector3(x, 0.08, zz), Color(0.12, 0.12, 0.13))
		Lot.cylindre(0.35, 0.02, Vector3(x + 10.0, 0.08, rng.randf_range(-3.0, 3.0)), Lot.couleur(Color(0.18, 0.18, 0.19)))
		x += 25.0
	# Réverbères des rues transversales
	for xs in rues_ns:
		var z2 := -135.0
		while z2 < 110.0:
			if absf(z2) > 20.0:
				lampadaire(Vector3(xs + 5.9, 0, z2), -PI * 0.5)
			z2 += 28.0


static func _feu_tricolore(pos: Vector3, vers_ouest: bool) -> void:
	var gris := Lot.couleur(Color(0.25, 0.27, 0.28))
	Lot.cylindre(0.08, 3.4, pos + Vector3(0, 1.7, 0), gris)
	var s: float = -1.0 if vers_ouest else 1.0
	var tete := pos + Vector3(0, 2.9, 0)
	Lot.boite(Vector3(0.35, 1.0, 0.3), tete, Lot.couleur(Color(0.1, 0.1, 0.1)))
	var feux := [Color(0.25, 0.05, 0.05), Color(0.3, 0.2, 0.02), Color(0.2, 1.0, 0.4)]
	for k in 3:
		var em: float = 3.0 if k == 2 else 0.0
		Lot.boite(Vector3(0.05, 0.22, 0.22), tete + Vector3(-s * 0.2, 0.3 - k * 0.3, 0), Lot.couleur(feux[k], em))
	# Petit feu piéton
	Lot.boite(Vector3(0.25, 0.5, 0.25), pos + Vector3(0, 2.0, 0), Lot.couleur(Color(0.1, 0.1, 0.1)))
	Lot.boite(Vector3(0.26, 0.18, 0.18), pos + Vector3(0, 1.88, 0), Lot.couleur(Color(0.2, 0.9, 0.35), 2.0))


static func _abribus(racine: Node3D, pos: Vector3, cote: float) -> void:
	# "cote" : +1 si le trottoir est au nord de la chaussée (abri ouvert vers +z)
	var alu := Lot.couleur(Color(0.6, 0.62, 0.64))
	Lot.boite(Vector3(5.0, 0.12, 1.7), pos + Vector3(0, 2.6, 0), alu)
	Lot.boite(Vector3(5.0, 2.3, 0.06), pos + Vector3(0, 1.35, -cote * 0.8), Tex.vitre())
	for sx in [-2.5, 2.5]:
		Lot.boite(Vector3(0.06, 2.3, 1.2), pos + Vector3(sx, 1.35, -cote * 0.2), Tex.vitre())
		Lot.boite(Vector3(0.1, 2.6, 0.1), pos + Vector3(sx, 1.3, -cote * 0.8), alu)
	Lot.boite(Vector3(1.3, 1.9, 0.12), pos + Vector3(2.0, 1.35, -cote * 0.74), Lot.couleur(Color(0.95, 0.95, 0.9), 0.8))
	Lot.boite(Vector3(2.5, 0.08, 0.4), pos + Vector3(-0.5, 0.5, -cote * 0.55), alu)
	Lot.cylindre(0.05, 3.0, pos + Vector3(-3.2, 1.5, cote * 0.5), alu)
	Lot.boite(Vector3(0.6, 0.6, 0.05), pos + Vector3(-3.2, 2.9, cote * 0.5), Lot.couleur(Color(0.1, 0.35, 0.65)))
	var t := Geo.texte(racine, "BUS", pos + Vector3(-3.2, 2.9, cote * 0.53), 26, Color(1, 1, 1), false)
	t.outline_size = 0
	if cote < 0.0:
		t.basis = Basis(Vector3.UP, PI)
		t.position.z = pos.z + cote * 0.53
	Geo.texte(racine, "Ligne 3 · Joué Centre ↔ Les Tilleuls", pos + Vector3(0, 2.35, -cote * 0.75), 18, Color(0.1, 0.1, 0.12), false).basis = Basis.IDENTITY if cote > 0.0 else Basis(Vector3.UP, PI)


static func _banc(p: Vector3, angle: float) -> void:
	var b := Basis(Vector3.UP, angle)
	var bois := Lot.couleur(Color(0.5, 0.35, 0.2))
	Lot.boite(Vector3(1.8, 0.06, 0.45), p + b * Vector3(0, 0.45, 0), bois, b)
	Lot.boite(Vector3(1.8, 0.4, 0.06), p + b * Vector3(0, 0.7, -0.22), bois, b)
	for sx in [-0.75, 0.75]:
		Lot.boite(Vector3(0.06, 0.45, 0.45), p + b * Vector3(sx, 0.22, 0), Lot.couleur(FER), b)


static func lampadaire(pos: Vector3, angle: float) -> void:
	var b := Basis(Vector3.UP, angle)
	var fonte := Lot.couleur(Color(0.18, 0.2, 0.2))
	Lot.cylindre(0.09, 5.0, pos + Vector3(0, 2.5, 0), fonte)
	Lot.boite(Vector3(0.08, 0.08, 1.3), pos + b * Vector3(0, 4.9, 0.6), fonte, b)
	Lot.boite(Vector3(0.4, 0.15, 0.6), pos + b * Vector3(0, 4.85, 1.2), fonte, b)
	Lot.boite(Vector3(0.3, 0.04, 0.45), pos + b * Vector3(0, 4.76, 1.2), Lot.couleur(Color(1.0, 0.92, 0.75), 1.5), b)


# ---------------------------------------------------------------------------
# Pavillons
# ---------------------------------------------------------------------------

## Fenêtre de maison : encadrement blanc, vitre, volets battants de couleur.
static func fenetre_maison(pied: Vector3, b: Basis, a: float, y: float, volets: Color, l: float = 1.1, h: float = 1.3) -> void:
	Lot.boite(Vector3(l + 0.16, h + 0.16, 0.06), _p(pied, b, a, y, 0.02), Lot.couleur(Color(0.96, 0.96, 0.94)), b)
	Lot.boite(Vector3(l, h, 0.06), _p(pied, b, a, y, 0.05), Tex.vitre(), b)
	Lot.boite(Vector3(l + 0.2, 0.08, 0.18), _p(pied, b, a, y - h * 0.5 - 0.06, 0.08), Lot.couleur(Color(0.9, 0.88, 0.84)), b)
	for cote in [-1.0, 1.0]:
		Lot.boite(Vector3(l * 0.5, h + 0.1, 0.05), _p(pied, b, a + cote * (l * 0.75 + 0.1), y, 0.05), Lot.couleur(volets), b)


static func maison(rng: RandomNumberGenerator, centre: Vector3, face: float, larg: float, prof: float, h: float, etage: bool, avant: Vector3, haie: Color) -> void:
	var n := Vector3(0, 0, face)
	var b := _base(n)
	var pied := centre + n * (prof * 0.5)
	var volets: Color = [Color(0.4, 0.5, 0.6), Color(0.85, 0.85, 0.82), Color(0.35, 0.45, 0.3), Color(0.55, 0.3, 0.2), Color(0.6, 0.65, 0.7)][rng.randi() % 5]
	var etages: Array = [1.5]
	if etage:
		etages.append(4.2)
	for y in etages:
		for a in [-larg * 0.3, larg * 0.3 - (0.0 if y > 2.0 else 10.0)]:
			if a > -larg * 0.5:
				fenetre_maison(pied, b, a, y, volets)
	# Fenêtres à l'arrière (côté jardin) et baie vitrée
	var b2 := _base(-n)
	var pied2 := centre - n * (prof * 0.5)
	Lot.boite(Vector3(2.6, 2.1, 0.06), _p(pied2, b2, -larg * 0.15, 1.05, 0.04), Tex.vitre(), b2)
	Lot.boite(Vector3(2.8, 0.1, 0.1), _p(pied2, b2, -larg * 0.15, 2.15, 0.05), Lot.couleur(Color(0.95, 0.95, 0.93)), b2)
	fenetre_maison(pied2, b2, larg * 0.3, 1.5, volets)
	if etage:
		fenetre_maison(pied2, b2, -larg * 0.25, 4.2, volets)
		fenetre_maison(pied2, b2, larg * 0.25, 4.2, volets)
	# Terrasse
	Lot.boite_c(Vector3(4.0, 0.15, 3.0), _p(pied2, b2, -larg * 0.15, 0.08, 1.5), Color(0.75, 0.7, 0.62))
	# Marquise au-dessus de la porte, perron
	Lot.boite(Vector3(1.6, 0.08, 0.9), _p(pied, b, larg * 0.2, 2.35, 0.45), Lot.couleur(Color(0.3, 0.3, 0.32)), b)
	Lot.boite_c(Vector3(1.8, 0.3, 1.0), _p(pied, b, larg * 0.2, 0.15, 0.5), Color(0.78, 0.76, 0.72))
	# Cheminée
	if rng.randf() < 0.7:
		Lot.boite_c(Vector3(0.7, 2.0, 0.7), centre + Vector3(rng.randf_range(-larg * 0.3, larg * 0.3), h + 1.6, rng.randf_range(-1.0, 1.0)), Color(0.85, 0.8, 0.72))
	# Clôture côté rue : portail, boîte aux lettres, allée
	var gate: Color = volets.darkened(0.2)
	Lot.boite(Vector3(3.0, 1.2, 0.08), avant + Vector3(1.0, 0.6, -face * 0.4), Lot.couleur(gate))
	for px in [-0.6, 2.6]:
		Lot.boite_c(Vector3(0.4, 1.5, 0.4), avant + Vector3(px, 0.75, -face * 0.4), Color(0.88, 0.86, 0.8))
	Lot.boite_c(Vector3(0.4, 0.35, 0.3), avant + Vector3(-0.6, 1.2, -face * 0.62), Color(0.95, 0.95, 0.92))
	Lot.boite_c(Vector3(2.8, 0.03, 5.0), avant + Vector3(1.0, 0.07, -face * 3.0), Color(0.72, 0.68, 0.6))
	# Jardin de derrière : piscine, balançoire, abri de jardin ou potager
	var r := rng.randf()
	var jardin := centre - n * (prof * 0.5 + 7.0)
	if r < 0.18:
		Lot.boite_c(Vector3(7.4, 0.12, 4.4), jardin + Vector3(0, 0.06, 0), Color(0.92, 0.92, 0.9))
		Lot.boite(Vector3(6.8, 0.04, 3.8), jardin + Vector3(0, 0.13, 0), Lot.couleur(Color(0.2, 0.6, 0.8), 0.15))
	elif r < 0.4:
		Lot.boite_c(Vector3(2.6, 2.2, 2.0), jardin + Vector3(rng.randf_range(-3, 3), 1.1, 0), Color(0.5, 0.4, 0.28))
		Lot.toit(2.0, 0.6, 2.9, jardin + Vector3(0, 2.2, 0), Lot.couleur(Color(0.25, 0.3, 0.25)), Basis(Vector3.UP, PI * 0.5))
	elif r < 0.55:
		for k in 4:
			Lot.boite_c(Vector3(3.0, 0.25, 0.8), jardin + Vector3(-2.0, 0.12, -1.5 + k * 1.1), Color(0.35, 0.25, 0.15))
			Lot.boite_c(Vector3(2.8, 0.3, 0.5), jardin + Vector3(-2.0, 0.35, -1.5 + k * 1.1), Color(0.3, 0.5, 0.2))
	elif r < 0.65:
		for sx in [-1.2, 1.2]:
			Lot.boite(Vector3(0.08, 2.4, 0.08), jardin + Vector3(sx, 1.2, -0.6), Lot.couleur(Color(0.3, 0.5, 0.7)), Basis(Vector3.RIGHT, 0.25))
			Lot.boite(Vector3(0.08, 2.4, 0.08), jardin + Vector3(sx, 1.2, 0.6), Lot.couleur(Color(0.3, 0.5, 0.7)), Basis(Vector3.RIGHT, -0.25))
		Lot.boite_c(Vector3(2.6, 0.08, 0.08), jardin + Vector3(0, 2.35, 0), Color(0.3, 0.5, 0.7))
		Lot.boite_c(Vector3(0.5, 0.05, 0.25), jardin + Vector3(0, 0.5, 0), Color(0.8, 0.2, 0.2))
	# Clôture grillagée sur les côtés de la parcelle
	for sx in [-8.0, 8.0]:
		Lot.boite_c(Vector3(0.05, 1.2, 18.0), avant + Vector3(sx, 0.6, -face * 9.5), Color(0.25, 0.35, 0.25))


# ---------------------------------------------------------------------------
# Arbres
# ---------------------------------------------------------------------------

const FEUILLAGES: Array = [Color(0.36, 0.5, 0.24), Color(0.42, 0.56, 0.27), Color(0.3, 0.45, 0.22), Color(0.48, 0.58, 0.3), Color(0.34, 0.47, 0.28)]


## Arbre feuillu détaillé : tronc effilé, maîtresses branches et houppier fait de plusieurs touffes.
## "platane" : écorce claire tachetée, houppier plus large.
static func arbre(pos: Vector3, taille: float, rng: RandomNumberGenerator, platane: bool = false) -> void:
	var h_tronc := (3.6 if platane else 3.0) * taille
	var r := 0.2 * taille
	var ecorce := Lot.couleur(Color(0.62, 0.58, 0.48) if platane else Color(0.4, 0.33, 0.26))
	Lot.cylindre(r, h_tronc, pos + Vector3(0, h_tronc * 0.5, 0), ecorce)
	Lot.cylindre(r * 1.35, 0.5, pos + Vector3(0, 0.25, 0), ecorce)
	var feuille := Tex.mat_feuillage(FEUILLAGES[rng.randi() % FEUILLAGES.size()])
	var feuille2 := Tex.mat_feuillage(FEUILLAGES[rng.randi() % FEUILLAGES.size()])
	var R := (2.5 if platane else 2.1) * taille
	var cime := pos + Vector3(0, h_tronc + R * 0.75, 0)
	# Branches maîtresses
	for k in 3:
		var ang := k * TAU / 3.0 + rng.randf_range(-0.4, 0.4)
		var dir := Vector3(cos(ang), 1.4, sin(ang)).normalized()
		var axe := Basis(Vector3.UP.cross(dir).normalized(), Vector3.UP.angle_to(dir))
		Lot.cylindre(r * 0.5, R * 1.1, pos + Vector3(0, h_tronc * 0.85, 0) + dir * R * 0.5, ecorce, axe)
	# Houppier : une touffe centrale et une couronne de touffes irrégulières
	Lot.sphere(R * 0.85, cime, feuille, 0.85)
	var n := 6 + rng.randi() % 3
	for k in n:
		var ang := k * TAU / n + rng.randf_range(-0.3, 0.3)
		var d := R * rng.randf_range(0.5, 0.75)
		var p := cime + Vector3(cos(ang) * d, rng.randf_range(-0.35, 0.45) * R, sin(ang) * d)
		Lot.sphere(R * rng.randf_range(0.5, 0.7), p, feuille if k % 2 == 0 else feuille2, rng.randf_range(0.7, 0.9))
	Lot.sphere(R * 0.55, cime + Vector3(rng.randf_range(-0.3, 0.3) * R, R * 0.55, rng.randf_range(-0.3, 0.3) * R), feuille2, 0.8)


# ---------------------------------------------------------------------------
# Place piétonne à côté du centre de secours
# ---------------------------------------------------------------------------

## Place dallée entre la caserne et la rocade : fontaine, deux alignements d'arbres,
## pelouses fleuries, bancs tournés vers la fontaine, monument aux morts au fond.
static func placette(racine: Node3D, rng: RandomNumberGenerator) -> void:
	var r := Rect2(-327.0, -100.0, 33.0, 62.0)
	var c2 := r.get_center()
	var ce := Vector3(c2.x, 0, c2.y)
	var pierre_claire := Color(0.86, 0.82, 0.72)
	# Dallage clair et bordure de granit
	Geo.boite_mat(racine, Vector3(r.size.x, 0.04, r.size.y), Vector3(ce.x, 0.06, ce.z), Tex.mat_beton(Color(1.0, 0.95, 0.85)), false)
	for cote in [-1.0, 1.0]:
		Lot.boite_c(Vector3(r.size.x, 0.12, 0.3), ce + Vector3(0, 0.08, cote * r.size.y * 0.5), Color(0.5, 0.5, 0.52))
		Lot.boite_c(Vector3(0.3, 0.12, r.size.y), ce + Vector3(cote * r.size.x * 0.5, 0.08, 0), Color(0.5, 0.5, 0.52))
	# Bandes de pavés sombres en croix
	Lot.boite_c(Vector3(r.size.x - 1.0, 0.01, 1.2), ce + Vector3(0, 0.085, 0), Color(0.45, 0.43, 0.4))
	Lot.boite_c(Vector3(1.2, 0.01, r.size.y - 1.0), ce + Vector3(0, 0.085, 0), Color(0.45, 0.43, 0.4))
	# Fontaine : bassin rond, eau, colonne et vasque
	var pf := ce + Vector3(0, 0, 4.0)
	Lot.cylindre(4.6, 0.12, pf + Vector3(0, 0.1, 0), Lot.couleur(Color(0.45, 0.43, 0.4)))
	Lot.cylindre(4.0, 0.5, pf + Vector3(0, 0.31, 0), Lot.couleur(pierre_claire))
	# Eau du bassin, juste au-dessus de la margelle intérieure
	Lot.cylindre(3.7, 0.04, pf + Vector3(0, 0.575, 0), Lot.couleur(Color(0.18, 0.36, 0.45), 0.08))
	Lot.cylindre(0.45, 1.8, pf + Vector3(0, 1.3, 0), Lot.couleur(pierre_claire))
	Lot.cylindre(1.4, 0.25, pf + Vector3(0, 2.2, 0), Lot.couleur(pierre_claire))
	Lot.cylindre(1.25, 0.04, pf + Vector3(0, 2.33, 0), Lot.couleur(Color(0.2, 0.4, 0.5), 0.08))
	Lot.sphere(0.35, pf + Vector3(0, 2.6, 0), Lot.couleur(pierre_claire))
	# Jet d'eau au sommet
	Lot.cone(0.12, 0.9, pf + Vector3(0, 3.2, 0), Lot.couleur(Color(0.8, 0.9, 1.0), 0.4))
	var corps := StaticBody3D.new()
	corps.position = pf + Vector3(0, 0.5, 0)
	racine.add_child(corps)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 4.0
	cyl.height = 1.0
	cs.shape = cyl
	corps.add_child(cs)
	# Bancs tournés vers la fontaine
	for i in 6:
		var a := i * TAU / 6.0 + TAU / 12.0
		var p := pf + Vector3(cos(a) * 7.0, 0.08, sin(a) * 7.0)
		var vers := (pf - p).normalized()
		var ang := atan2(vers.x, vers.z)
		var mod: String = Modeles.MOBILIER["banc_bois"] if i % 2 == 0 else Modeles.MOBILIER["banc_metal"]
		if Modeles.poser(racine, Modeles.RUE, p, ang + Modeles.BANC_ROT, 1.0, mod, false) == null:
			_banc(p, ang)
	# Pelouses fleuries aux quatre coins de la fontaine
	var fleurs: Array = [Color(0.85, 0.15, 0.2), Color(0.95, 0.8, 0.1), Color(0.95, 0.95, 0.95), Color(0.6, 0.3, 0.75)]
	for q in [Vector3(-9.0, 0, -9.0), Vector3(9.0, 0, -9.0), Vector3(-9.0, 0, 15.0), Vector3(9.0, 0, 15.0)]:
		var pq: Vector3 = ce + q
		Lot.boite_c(Vector3(9.0, 0.25, 9.0), pq + Vector3(0, 0.12, 0), Color(0.6, 0.58, 0.54))
		Geo.boite_mat(racine, Vector3(8.6, 0.06, 8.6), pq + Vector3(0, 0.24, 0), Tex.mat_herbe(), false)
		# Bordure de fleurs : petites touffes serrées, une couleur par côté
		for cote in 4:
			var bc := Basis(Vector3.UP, cote * PI * 0.5)
			var coul: Color = fleurs[(cote + int(absf(q.z))) % 4]
			for k in 18:
				var pk := pq + bc * Vector3(-3.6 + k * 0.42, 0, 3.7) + Vector3(0, 0.3, 0)
				Lot.sphere(0.16, pk, Lot.couleur(Color(0.25, 0.45, 0.2)), 0.7)
				Lot.sphere(0.1, pk + Vector3(0, 0.1, 0), Lot.couleur(coul), 0.6)
		if Modeles.poser(racine, Modeles.PLANTES, pq + Vector3(0, 0.27, 0), rng.randf() * TAU, 0.45, "Plants*#%d" % (9 + rng.randi() % 6), false) == null:
			Lot.sphere(1.0, pq + Vector3(0, 0.7, 0), Tex.mat_feuillage(FEUILLAGES[0]), 0.7)
	# Deux alignements d'arbres avec grilles au pied, lampadaires entre les arbres
	var z := r.position.y + 5.0
	var n := 0
	while z < r.end.y - 3.0:
		for x in [r.position.x + 2.5, r.end.x - 2.5]:
			var pa := Vector3(x, 0.08, z)
			Lot.boite_c(Vector3(1.4, 0.02, 1.4), pa, Color(0.15, 0.15, 0.16))
			var nom: String = "Tree 1" if n % 2 == 0 else "Tree 2"
			if Modeles.poser(racine, Modeles.ARBRE, pa, rng.randf() * TAU, rng.randf_range(1.1, 1.3), nom, false) == null:
				arbre(pa, rng.randf_range(0.9, 1.1), rng)
			if n % 2 == 1:
				lampadaire(Vector3(x, 0.08, z - 4.0), PI * 0.5 if x < ce.x else -PI * 0.5)
			n += 1
		z += 8.0
	# Poubelles et jardinières aux entrées
	for p in [ce + Vector3(-3.0, 0.08, r.size.y * 0.5 - 1.5), ce + Vector3(3.0, 0.08, r.size.y * 0.5 - 1.5), ce + Vector3(-5.0, 0.08, -r.size.y * 0.5 + 12.0)]:
		Modeles.poser(racine, Modeles.RUE, p, 0.0, 1.0, Modeles.MOBILIER["poubelle"], false)
	for p in [ce + Vector3(-6.0, 0.08, r.size.y * 0.5 - 1.5), ce + Vector3(6.0, 0.08, r.size.y * 0.5 - 1.5)]:
		if Modeles.poser(racine, Modeles.RUE, p, 0.0, 1.0, Modeles.MOBILIER["jardiniere"], false) == null:
			Lot.boite_c(Vector3(1.6, 0.6, 0.7), p + Vector3(0, 0.3, 0), Color(0.5, 0.5, 0.52))
	# Monument aux morts au fond de la place
	var pm := ce + Vector3(0, 0.08, -r.size.y * 0.5 + 5.0)
	for k in 3:
		Lot.boite_c(Vector3(5.0 - k * 1.0, 0.25, 4.0 - k * 1.0), pm + Vector3(0, 0.125 + k * 0.25, 0), Color(0.6, 0.6, 0.6))
	Lot.boite_c(Vector3(1.6, 3.2, 1.2), pm + Vector3(0, 2.35, 0), pierre_claire)
	Lot.boite_c(Vector3(1.0, 2.0, 0.8), pm + Vector3(0, 4.95, 0), pierre_claire)
	Lot.boite_c(Vector3(0.9, 0.5, 0.7), pm + Vector3(0, 6.2, 0), pierre_claire, Basis(Vector3.UP, PI * 0.25))
	Lot.sphere(0.35, pm + Vector3(0, 6.7, 0), Lot.couleur(Color(0.35, 0.45, 0.38)))
	var ins := Geo.texte(racine, "À NOS MORTS\n1914 - 1918\n1939 - 1945", pm + Vector3(0, 2.6, 0.61), 26, Color(0.25, 0.25, 0.25), false)
	ins.outline_size = 0
	ins.pixel_size = 0.006
	for sx in [-2.8, 2.8]:
		Lot.cylindre(0.08, 0.9, pm + Vector3(sx, 0.45, 2.6), Lot.couleur(Color(0.1, 0.1, 0.1)))
		Lot.sphere(0.1, pm + Vector3(sx, 0.92, 2.6), Lot.couleur(Color(0.1, 0.1, 0.1)))
	Lot.boite_c(Vector3(5.6, 0.04, 0.04), pm + Vector3(0, 0.75, 2.6), Color(0.1, 0.1, 0.1))
	var corps2 := StaticBody3D.new()
	corps2.position = pm + Vector3(0, 1.5, 0)
	racine.add_child(corps2)
	var cs2 := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(5.0, 3.0, 4.0)
	cs2.shape = bx
	corps2.add_child(cs2)
	# Nom de la place
	var t := Geo.texte(racine, "Place des Tilleuls", ce + Vector3(0, 2.6, r.size.y * 0.5 + 0.2), 40, Color(0.95, 0.95, 0.9), false)
	t.outline_size = 6
	Lot.boite_c(Vector3(0.08, 2.4, 0.08), ce + Vector3(-1.6, 1.2, r.size.y * 0.5 + 0.2), FER)
	Lot.boite_c(Vector3(0.08, 2.4, 0.08), ce + Vector3(1.6, 1.2, r.size.y * 0.5 + 0.2), FER)
