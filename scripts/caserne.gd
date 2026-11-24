## Intérieur et abords du centre de secours : vestiaire, local ARI, salle de garde et cuisine,
## bureau du standard, chambres, salle de sport, rangements de la remise, cour arrière avec
## la tour de manœuvre et parking du personnel.
## Le bâtiment (murs, portes de remise, toit) est construit par monde.gd ; ici on le remplit.
## Plan (vu de dessus, façade sur la rue en z = -14) :
##   remise des engins : z -54 → -14 ; pièces de vie au fond : z -70 → -54
##   vestiaire x -285 → -269 | local ARI -269 → -259 | salle de garde -259 → -233 | bureau et chambres -233 → -215
extends RefCounted

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")
const Lot = preload("res://scripts/lot.gd")
const VoitureModele = preload("res://scripts/voiture_modele.gd")
const Modeles = preload("res://scripts/modeles3d.gd")

const CLOISON := Color(0.9, 0.88, 0.82)
const MARINE := Color(0.1, 0.13, 0.22)
const JAUNE := Color(0.95, 0.78, 0.1)
const ROUGE := Color(0.72, 0.08, 0.06)
const METAL := Color(0.6, 0.62, 0.64)
const BOIS := Color(0.55, 0.4, 0.26)
const HAUT := 3.2   # hauteur sous plafond des pièces de vie


static func construire(racine: Node3D) -> void:
	_cloisons(racine)
	_vestiaire(racine)
	_local_ari(racine)
	_salle_de_garde(racine)
	_bureau(racine)
	_chambres(racine)
	_remise(racine)
	_salle_de_sport(racine)
	_cour_et_tour(racine)
	_parking_personnel(racine)


# ---------------------------------------------------------------------------
# Outils
# ---------------------------------------------------------------------------

## Meuble : visuel regroupé (Lot) et, si "solide", une collision pour ne pas le traverser.
static func _meuble(racine: Node3D, taille: Vector3, pos: Vector3, c: Color, solide: bool = false, base: Basis = Basis.IDENTITY) -> void:
	Lot.boite_c(taille, pos, c, base)
	if solide:
		var corps := StaticBody3D.new()
		corps.transform = Transform3D(base, pos)
		racine.add_child(corps)
		var cs := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = taille
		cs.shape = forme
		corps.add_child(cs)


## Volume de collision seul (invisible).
static func _collision(racine: Node3D, taille: Vector3, pos: Vector3) -> void:
	var corps := StaticBody3D.new()
	corps.position = pos
	racine.add_child(corps)
	var cs := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = taille
	cs.shape = forme
	corps.add_child(cs)


static func _lumiere(racine: Node3D, pos: Vector3, portee: float, energie: float = 0.8) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.omni_range = portee
	l.light_energy = energie
	l.light_color = Color(1.0, 0.96, 0.88)
	racine.add_child(l)
	# Plafonnier
	Lot.boite(Vector3(1.2, 0.05, 0.3), pos + Vector3(0, HAUT - 0.03 - pos.y, 0), Tex.emissif(Color(1.0, 0.98, 0.92), 1.5))


## Panneau d'affichage (liège) avec des feuilles punaisées et un titre.
## "rot" : orientation du panneau ; sa face lisible regarde vers +z dans son repère.
static func _panneau(racine: Node3D, titre: String, pos: Vector3, rot: float, l: float = 1.6, h: float = 1.0) -> void:
	var b := Basis(Vector3.UP, rot)
	Lot.boite_c(Vector3(l + 0.08, h + 0.08, 0.03), pos, Color(0.45, 0.3, 0.18), b)
	Lot.boite_c(Vector3(l, h, 0.035), pos, Color(0.72, 0.55, 0.36), b)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(pos.x * 31.0 + pos.z * 17.0))
	var n := int(l / 0.3)
	for i in n:
		for j in 2:
			var fx := -l * 0.5 + 0.2 + i * (l - 0.3) / maxf(1.0, n - 1.0) + rng.randf_range(-0.03, 0.03)
			var fy := -h * 0.5 + 0.25 + j * 0.38 + rng.randf_range(-0.03, 0.03)
			var c := Color(0.97, 0.97, 0.94) if rng.randf() < 0.75 else Color(1.0, 0.92, 0.55)
			Lot.boite_c(Vector3(0.21, 0.29, 0.005), pos + b * Vector3(fx, fy - 0.08, 0.022), c, b * Basis(Vector3.BACK, rng.randf_range(-0.06, 0.06)))
	var t := Geo.texte(racine, titre, pos + b * Vector3(0, h * 0.5 - 0.09, 0.03), 18, Color(0.1, 0.1, 0.1), false)
	t.outline_size = 0
	t.basis = b


## Écriteau au-dessus d'une porte ou sur un mur.
static func _ecriteau(racine: Node3D, texte: String, pos: Vector3, rot: float, fond: Color = Color(0.1, 0.25, 0.55)) -> void:
	var b := Basis(Vector3.UP, rot)
	Lot.boite_c(Vector3(0.12 * texte.length() + 0.3, 0.3, 0.03), pos, fond, b)
	var t := Geo.texte(racine, texte, pos + b * Vector3(0, 0, 0.02), 22, Color.WHITE, false)
	t.outline_size = 0
	t.basis = b


static func _extincteur(pos: Vector3) -> void:
	Lot.cylindre(0.09, 0.5, pos + Vector3(0, 0.35, 0), Geo.mat(ROUGE))
	Lot.boite_c(Vector3(0.06, 0.08, 0.06), pos + Vector3(0, 0.64, 0), Color(0.12, 0.12, 0.12))


## Chaise simple, tournée de "rot".
static func _chaise(pos: Vector3, rot: float, c: Color = Color(0.2, 0.22, 0.25)) -> void:
	var b := Basis(Vector3.UP, rot)
	Lot.boite_c(Vector3(0.44, 0.05, 0.42), pos + Vector3(0, 0.46, 0), c, b)
	Lot.boite_c(Vector3(0.44, 0.45, 0.04), pos + b * Vector3(0, 0.7, -0.2), c, b)
	for dx in [-0.19, 0.19]:
		for dz in [-0.18, 0.18]:
			Lot.boite_c(Vector3(0.03, 0.45, 0.03), pos + b * Vector3(dx, 0.22, dz), METAL, b)


## Veste et pantalon de feu suspendus (tissu marine, bandes jaunes et grises).
static func _tenue_suspendue(pos: Vector3, rot: float) -> void:
	var b := Basis(Vector3.UP, rot)
	Lot.boite_c(Vector3(0.56, 0.78, 0.2), pos, MARINE, b)
	for y in [-0.3, -0.05]:
		Lot.boite_c(Vector3(0.57, 0.05, 0.21), pos + b * Vector3(0, y, 0), JAUNE, b)
		Lot.boite_c(Vector3(0.57, 0.02, 0.215), pos + b * Vector3(0, y, 0), Color(0.8, 0.82, 0.85), b)
	for sx in [-0.32, 0.32]:
		Lot.boite_c(Vector3(0.12, 0.66, 0.16), pos + b * Vector3(sx, -0.05, 0), MARINE, b)
	Lot.boite_c(Vector3(0.48, 0.85, 0.16), pos + b * Vector3(0, -0.85, 0.02), MARINE, b)
	Lot.boite_c(Vector3(0.49, 0.05, 0.17), pos + b * Vector3(0, -1.05, 0.02), JAUNE, b)


## Casque de feu posé (calotte blanche, visière dorée).
static func _casque(pos: Vector3) -> void:
	Lot.sphere(0.15, pos + Vector3(0, 0.08, 0), Geo.mat(Color(0.93, 0.93, 0.9)), 0.85)
	Lot.boite_c(Vector3(0.27, 0.03, 0.3), pos, Color(0.85, 0.85, 0.82))
	Lot.boite_c(Vector3(0.2, 0.07, 0.02), pos + Vector3(0, 0.02, 0.15), Color(0.85, 0.65, 0.2))


static func _bouteille_ari(pos: Vector3, couchee: bool = false) -> void:
	var b := Basis(Vector3.FORWARD, PI * 0.5) if couchee else Basis.IDENTITY
	Lot.cylindre(0.08, 0.62, pos, Geo.mat(Color(0.15, 0.15, 0.16)), b)
	Lot.cylindre(0.081, 0.12, pos + b * Vector3(0, 0.25, 0), Geo.mat(JAUNE), b)
	Lot.cylindre(0.025, 0.08, pos + b * Vector3(0, 0.35, 0), Geo.mat(METAL), b)


## Étagère métallique à "n" niveaux, longue selon "rot".
static func _etagere(racine: Node3D, pos: Vector3, rot: float, l: float, p: float, h: float, n: int) -> void:
	var b := Basis(Vector3.UP, rot)
	for sx in [-l * 0.5, l * 0.5]:
		for sz in [-p * 0.5, p * 0.5]:
			Lot.boite_c(Vector3(0.04, h, 0.04), pos + b * Vector3(sx, h * 0.5, sz), Color(0.3, 0.32, 0.35), b)
	for k in n:
		Lot.boite_c(Vector3(l, 0.03, p), pos + b * Vector3(0, 0.15 + k * (h - 0.2) / maxf(1.0, n - 1.0), 0), Color(0.5, 0.52, 0.55), b)
	var corps := StaticBody3D.new()
	corps.transform = Transform3D(b, pos + Vector3(0, h * 0.5, 0))
	racine.add_child(corps)
	var cs := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(l, h, p)
	cs.shape = forme
	corps.add_child(cs)


# ---------------------------------------------------------------------------
# Cloisons et plafond des pièces de vie
# ---------------------------------------------------------------------------

static func _cloisons(racine: Node3D) -> void:
	# Côté remise : portes du vestiaire, de la salle de garde et du bureau
	Geo.mur(racine, "x", -54.0, -285.0, -215.0, 0.0, HAUT, 0.2, CLOISON, [[-276.0, 2.0, 0.0, 2.2], [-250.0, 2.0, 0.0, 2.2], [-224.0, 2.0, 0.0, 2.2]])
	# Cloisons entre les pièces (porte côté remise, en z = -57)
	for x in [-269.0, -259.0, -233.0]:
		Geo.mur(racine, "z", x, -70.0, -54.0, 0.0, HAUT, 0.15, CLOISON, [[-57.0, 1.0, 0.0, 2.15]])
	# Bureau / chambres
	Geo.mur(racine, "x", -62.0, -233.0, -215.0, 0.0, HAUT, 0.15, CLOISON, [[-224.0, 1.0, 0.0, 2.15]])
	# Plafond, plinthes et sol en carrelage clair
	Geo.boite(racine, Vector3(70.0, 0.12, 16.0), Vector3(-250, HAUT + 0.06, -62), Color(0.93, 0.93, 0.9), false)
	Geo.boite(racine, Vector3(69.6, 0.02, 15.8), Vector3(-250, 0.13, -62), Color(0.78, 0.76, 0.72), false)
	# Encadrements des portes côté remise
	for px in [-276.0, -250.0, -224.0]:
		for c in [-1.0, 1.0]:
			Lot.boite_c(Vector3(0.08, 2.25, 0.26), Vector3(px + c * 1.02, 1.12, -54.0), Color(0.35, 0.35, 0.38))
		Lot.boite_c(Vector3(2.12, 0.08, 0.26), Vector3(px, 2.24, -54.0), Color(0.35, 0.35, 0.38))


# ---------------------------------------------------------------------------
# Pièces de vie
# ---------------------------------------------------------------------------

static func _vestiaire(racine: Node3D) -> void:
	# Casiers individuels contre le mur du fond et le mur de gauche
	var rng := RandomNumberGenerator.new()
	rng.seed = 18
	for i in 14:
		_casier(racine, Vector3(-284.3 + 0.5 + i * 1.02, 0, -69.45), 0.0, rng)
	for i in 9:
		_casier(racine, Vector3(-284.45, 0, -68.2 + 0.5 + i * 1.02), PI * 0.5, rng)
	# Bancs au milieu
	for bx in [-279.5, -274.0]:
		Lot.boite_c(Vector3(3.2, 0.06, 0.4), Vector3(bx, 0.45, -63.5), BOIS)
		for dx in [-1.4, 1.4]:
			Lot.boite_c(Vector3(0.06, 0.42, 0.34), Vector3(bx + dx, 0.22, -63.5), METAL)
	# Tenues de feu suspendues contre la cloison du local ARI, casques et bottes dessous
	Lot.boite_c(Vector3(0.05, 0.05, 9.0), Vector3(-269.4, 2.15, -63.0), METAL)
	for i in 10:
		var z := -67.2 + i * 0.9
		_tenue_suspendue(Vector3(-269.55, 1.65, z), -PI * 0.5)
		_casque(Vector3(-269.55, 2.45, z))
		for dz in [-0.1, 0.1]:
			Lot.boite_c(Vector3(0.28, 0.35, 0.11), Vector3(-269.75, 0.3, z + dz), Color(0.06, 0.06, 0.06))
	Lot.boite_c(Vector3(0.3, 0.03, 9.0), Vector3(-269.55, 2.32, -63.0), METAL)
	# Miroir et lavabos près de la porte
	Lot.boite_c(Vector3(1.6, 0.9, 0.02), Vector3(-279.0, 1.6, -54.15), Color(0.75, 0.82, 0.86))
	Lot.boite_c(Vector3(1.4, 0.15, 0.45), Vector3(-279.0, 0.85, -54.35), Color(0.95, 0.95, 0.95))
	_panneau(racine, "CONSIGNES TENUE", Vector3(-283.0, 1.6, -54.13), PI, 1.2, 0.8)
	_ecriteau(racine, "VESTIAIRE", Vector3(-276.0, 2.55, -53.88), 0.0)
	_lumiere(racine, Vector3(-279.0, 2.9, -62.0), 9.0)
	_lumiere(racine, Vector3(-273.0, 2.9, -62.0), 9.0, 0.6)


static func _casier(racine: Node3D, pos: Vector3, rot: float, rng: RandomNumberGenerator) -> void:
	var b := Basis(Vector3.UP, rot)
	var gris := Color(0.38, 0.47, 0.6).lerp(Color(0.5, 0.52, 0.55), rng.randf() * 0.3)
	_meuble(racine, Vector3(0.98, 1.95, 0.5), pos + Vector3(0, 0.98, 0), gris, true, b)
	Lot.boite_c(Vector3(0.01, 1.85, 0.51), pos + b * Vector3(0, 0.98, 0.003), Color(0.15, 0.17, 0.2), b)
	for sx in [-0.25, 0.25]:
		for k in 3:
			Lot.boite_c(Vector3(0.22, 0.015, 0.505), pos + b * Vector3(sx, 1.7 - k * 0.04, 0.003), Color(0.2, 0.22, 0.26), b)
		Lot.boite_c(Vector3(0.03, 0.12, 0.52), pos + b * Vector3(sx * 0.3, 1.05, 0.006), Color(0.1, 0.1, 0.1), b)
		Lot.boite_c(Vector3(0.18, 0.06, 0.505), pos + b * Vector3(sx, 1.45, 0.003), Color(0.95, 0.95, 0.9), b)


static func _local_ari(racine: Node3D) -> void:
	# Râtelier des appareils respiratoires : dossard + bouteille, masques au-dessus
	_meuble(racine, Vector3(8.6, 0.06, 0.5), Vector3(-264.0, 1.0, -69.5), Color(0.5, 0.52, 0.55))
	for i in 8:
		var x := -267.6 + i * 1.03
		Lot.boite_c(Vector3(0.36, 0.6, 0.05), Vector3(x, 1.45, -69.7), Color(0.1, 0.1, 0.1))
		_bouteille_ari(Vector3(x, 1.4, -69.55))
		Lot.sphere(0.11, Vector3(x, 2.0, -69.6), Geo.mat(Color(0.12, 0.12, 0.13)), 1.2)
		Lot.boite_c(Vector3(0.14, 0.09, 0.03), Vector3(x, 2.0, -69.49), Color(0.75, 0.85, 0.9))
	_meuble(racine, Vector3(8.6, 2.6, 0.08), Vector3(-264.0, 1.3, -69.85), Color(0.86, 0.86, 0.84), true)
	# Réserve de bouteilles couchées
	_etagere(racine, Vector3(-268.4, 0, -62.0), PI * 0.5, 4.0, 0.6, 1.4, 3)
	for k in 3:
		for i in 6:
			_bouteille_ari(Vector3(-268.4, 0.24 + k * 0.6, -63.6 + i * 0.6), true)
	# Établi de contrôle et compresseur de recharge
	_meuble(racine, Vector3(2.4, 0.9, 0.8), Vector3(-261.5, 0.45, -66.5), Color(0.3, 0.42, 0.3), true)
	Lot.boite_c(Vector3(2.45, 0.05, 0.85), Vector3(-261.5, 0.92, -66.5), BOIS)
	Lot.sphere(0.12, Vector3(-261.9, 1.05, -66.4), Geo.mat(Color(0.12, 0.12, 0.13)), 1.2)
	Lot.boite_c(Vector3(0.35, 0.22, 0.25), Vector3(-261.0, 1.06, -66.5), Color(0.85, 0.85, 0.82))
	_meuble(racine, Vector3(1.2, 1.5, 0.9), Vector3(-260.0, 0.75, -60.0), Color(0.2, 0.36, 0.6), true)
	for i in 3:
		Lot.cylindre(0.06, 0.02, Vector3(-260.3 + i * 0.3, 1.2, -59.54), Geo.mat(Color(0.95, 0.95, 0.95)), Basis(Vector3.RIGHT, PI * 0.5))
	_panneau(racine, "CONTRÔLE DES ARI", Vector3(-264.0, 1.7, -54.13), PI, 1.4, 0.8)
	_ecriteau(racine, "LOCAL ARI", Vector3(-264.0, 2.7, -54.13), PI, Color(0.85, 0.55, 0.05))
	_lumiere(racine, Vector3(-264.0, 2.9, -62.0), 8.0)


static func _salle_de_garde(racine: Node3D) -> void:
	# Cuisine contre le mur du fond
	_meuble(racine, Vector3(8.0, 0.88, 0.62), Vector3(-254.0, 0.44, -69.55), Color(0.92, 0.92, 0.9), true)
	Lot.boite_c(Vector3(8.02, 0.04, 0.66), Vector3(-254.0, 0.9, -69.55), Color(0.25, 0.25, 0.27))
	for i in 10:
		Lot.boite_c(Vector3(0.01, 0.8, 0.005), Vector3(-257.6 + i * 0.8, 0.44, -69.235), Color(0.6, 0.6, 0.6))
		Lot.boite_c(Vector3(0.6, 0.7, 0.35), Vector3(-257.6 + i * 0.8, 2.15, -69.75), Color(0.92, 0.92, 0.9))
	Lot.boite_c(Vector3(0.7, 0.03, 0.45), Vector3(-255.0, 0.92, -69.5), Color(0.75, 0.77, 0.8))
	Lot.cylindre(0.015, 0.3, Vector3(-255.0, 1.05, -69.75), Geo.mat(METAL))
	Lot.boite_c(Vector3(0.6, 0.02, 0.5), Vector3(-252.6, 0.93, -69.5), Color(0.05, 0.05, 0.05))
	for i in 4:
		Lot.cylindre(0.09, 0.005, Vector3(-252.75 + (i % 2) * 0.3, 0.945, -69.62 + (i >> 1) * 0.25), Geo.mat(Color(0.2, 0.2, 0.2)))
	Lot.boite_c(Vector3(0.5, 0.3, 0.38), Vector3(-251.0, 1.07, -69.55), Color(0.15, 0.15, 0.15))
	Lot.boite_c(Vector3(0.22, 0.34, 0.28), Vector3(-256.5, 1.09, -69.55), Color(0.1, 0.1, 0.1))
	Lot.cylindre(0.05, 0.1, Vector3(-256.5, 0.97, -69.45), Geo.mat(Color(0.95, 0.95, 0.95)))
	# Réfrigérateur
	_meuble(racine, Vector3(0.75, 1.85, 0.7), Vector3(-249.4, 0.93, -69.5), Color(0.85, 0.86, 0.87), true)
	Lot.boite_c(Vector3(0.03, 0.6, 0.04), Vector3(-249.1, 1.2, -69.14), METAL)
	# Grande table existante et ses chaises, un deuxième coin repas
	_meuble(racine, Vector3(4.0, 0.06, 1.6), Vector3(-238.0, 0.88, -62.0), BOIS, true)
	for dx in [-1.85, 1.85]:
		for dz in [-0.7, 0.7]:
			Lot.boite_c(Vector3(0.07, 0.85, 0.07), Vector3(-238.0 + dx, 0.43, -62.0 + dz), Color(0.3, 0.3, 0.3))
	for i in 4:
		_chaise(Vector3(-239.5 + i, 0, -63.2), 0.0)
		_chaise(Vector3(-239.5 + i, 0, -60.8), PI)
	Lot.cylindre(0.05, 0.1, Vector3(-237.6, 0.96, -62.2), Geo.mat(Color(0.95, 0.95, 0.95)))
	Lot.cylindre(0.05, 0.1, Vector3(-238.9, 0.96, -61.8), Geo.mat(Color(0.8, 0.2, 0.15)))
	# Coin détente : canapé, table basse, télévision
	_meuble(racine, Vector3(0.9, 0.45, 2.4), Vector3(-254.5, 0.23, -61.0), Color(0.25, 0.3, 0.35), true)
	Lot.boite_c(Vector3(0.25, 0.5, 2.4), Vector3(-254.85, 0.7, -61.0), Color(0.25, 0.3, 0.35))
	for dz in [-1.3, 1.3]:
		Lot.boite_c(Vector3(0.9, 0.62, 0.2), Vector3(-254.5, 0.31, -61.0 + dz), Color(0.22, 0.27, 0.32))
	Lot.boite_c(Vector3(0.6, 0.35, 1.0), Vector3(-256.4, 0.18, -61.0), BOIS)
	Lot.boite_c(Vector3(0.05, 0.75, 1.3), Vector3(-258.85, 1.5, -61.0), Color(0.03, 0.03, 0.04))
	Lot.boite(Vector3(0.01, 0.68, 1.22), Vector3(-258.82, 1.5, -61.0), Tex.emissif(Color(0.25, 0.4, 0.6), 0.6))
	# Tableau de garde et consignes sur la cloison côté remise
	_panneau(racine, "TABLEAU DE GARDE", Vector3(-243.0, 1.6, -54.13), PI, 2.0, 1.1)
	_panneau(racine, "CONSIGNES OPÉRATIONNELLES", Vector3(-237.0, 1.6, -54.13), PI, 1.6, 1.0)
	_panneau(racine, "VIE DU CENTRE", Vector3(-233.1, 1.6, -66.0), -PI * 0.5, 1.4, 0.9)
	Lot.cylindre(0.17, 0.04, Vector3(-246.0, 2.5, -54.13), Geo.mat(Color(0.95, 0.95, 0.95)), Basis(Vector3.RIGHT, PI * 0.5))
	Lot.cylindre(0.15, 0.045, Vector3(-246.0, 2.5, -54.13), Geo.mat(Color(0.1, 0.1, 0.1)), Basis(Vector3.RIGHT, PI * 0.5))
	# Fontaine à eau et plante
	_meuble(racine, Vector3(0.35, 1.1, 0.35), Vector3(-233.4, 0.55, -55.0), Color(0.9, 0.9, 0.9))
	Lot.cylindre(0.15, 0.4, Vector3(-233.4, 1.3, -55.0), Geo.mat(Color(0.6, 0.75, 0.9, 0.6)))
	Lot.cylindre(0.2, 0.4, Vector3(-258.5, 0.2, -55.0), Geo.mat(Color(0.45, 0.25, 0.15)))
	Lot.sphere(0.4, Vector3(-258.5, 0.85, -55.0), Geo.mat(Color(0.2, 0.42, 0.18)), 1.3)
	_ecriteau(racine, "SALLE DE GARDE", Vector3(-250.0, 2.55, -53.88), 0.0)
	_lumiere(racine, Vector3(-253.0, 2.9, -63.0), 10.0)
	_lumiere(racine, Vector3(-239.0, 2.9, -62.0), 10.0)


static func _bureau(racine: Node3D) -> void:
	# Poste du standard : bureau en L, trois écrans, radio, téléphone
	_meuble(racine, Vector3(3.2, 0.05, 0.8), Vector3(-229.0, 0.76, -61.4), Color(0.85, 0.84, 0.8), true)
	_meuble(racine, Vector3(0.8, 0.05, 2.0), Vector3(-232.2, 0.76, -59.6), Color(0.85, 0.84, 0.8), true)
	for p in [Vector3(-230.4, 0.38, -61.7), Vector3(-227.6, 0.38, -61.7), Vector3(-232.5, 0.38, -58.8)]:
		Lot.boite_c(Vector3(0.05, 0.74, 0.5), p, Color(0.3, 0.3, 0.32))
	for i in 3:
		var x := -230.0 + i * 0.6
		Lot.boite_c(Vector3(0.55, 0.34, 0.03), Vector3(x, 1.1, -61.62), Color(0.05, 0.05, 0.06), Basis(Vector3.UP, (i - 1) * -0.25))
		Lot.boite(Vector3(0.5, 0.29, 0.005), Vector3(x, 1.1, -61.6), Tex.emissif([Color(0.2, 0.45, 0.8), Color(0.3, 0.7, 0.4), Color(0.8, 0.5, 0.2)][i], 0.8), Basis(Vector3.UP, (i - 1) * -0.25))
		Lot.boite_c(Vector3(0.05, 0.18, 0.05), Vector3(x, 0.87, -61.66), Color(0.1, 0.1, 0.1))
	Lot.boite_c(Vector3(0.45, 0.02, 0.15), Vector3(-229.4, 0.79, -61.15), Color(0.1, 0.1, 0.1))
	Lot.boite_c(Vector3(0.35, 0.14, 0.25), Vector3(-232.2, 0.85, -60.2), Color(0.15, 0.15, 0.15))
	Lot.boite_c(Vector3(0.04, 0.25, 0.04), Vector3(-232.3, 1.02, -60.2), Color(0.05, 0.05, 0.05))
	Lot.boite(Vector3(0.12, 0.05, 0.005), Vector3(-232.2, 0.87, -60.07), Tex.emissif(Color(0.3, 1.0, 0.4), 1.0))
	Lot.boite_c(Vector3(0.2, 0.06, 0.22), Vector3(-232.2, 0.8, -59.3), Color(0.1, 0.1, 0.1))
	_chaise(Vector3(-229.0, 0, -60.6), PI, Color(0.12, 0.12, 0.14))
	# Imprimante des tickets de départ
	_meuble(racine, Vector3(0.6, 0.9, 0.5), Vector3(-226.6, 0.45, -61.4), Color(0.85, 0.85, 0.85))
	Lot.boite_c(Vector3(0.45, 0.2, 0.4), Vector3(-226.6, 1.0, -61.4), Color(0.25, 0.25, 0.27))
	# Carte du secteur au mur, armoires à dossiers
	Lot.boite_c(Vector3(0.03, 1.4, 2.4), Vector3(-215.25, 1.6, -58.0), Color(0.95, 0.95, 0.92))
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	for i in 14:
		var horiz := rng.randf() < 0.5
		Lot.boite_c(Vector3(0.005, 0.03 if horiz else rng.randf_range(0.3, 1.2), rng.randf_range(0.5, 2.2) if horiz else 0.03), Vector3(-215.27, 1.6 + rng.randf_range(-0.6, 0.6), -58.0 + rng.randf_range(-1.0, 1.0)), Color(0.55, 0.55, 0.55))
	Lot.boite_c(Vector3(0.005, 0.25, 1.2), Vector3(-215.27, 1.3, -57.4), Color(0.45, 0.65, 0.95))
	for i in 6:
		Lot.sphere(0.03, Vector3(-215.27, 1.6 + rng.randf_range(-0.6, 0.6), -58.0 + rng.randf_range(-1.0, 1.0)), Geo.mat(ROUGE))
	var t := Geo.texte(racine, "SECTEUR DU CENTRE", Vector3(-215.28, 2.38, -58.0), 18, Color(0.1, 0.1, 0.1), false)
	t.outline_size = 0
	t.rotation.y = -PI * 0.5
	for i in 3:
		_meuble(racine, Vector3(0.5, 1.3, 0.6), Vector3(-216.0, 0.65, -55.2 - i * 0.55 - 0.3), Color(0.55, 0.57, 0.6), true)
	_panneau(racine, "ORDRE DU JOUR", Vector3(-219.0, 1.6, -61.92), 0.0, 1.4, 0.9)
	_ecriteau(racine, "BUREAU - STANDARD", Vector3(-224.0, 2.55, -53.88), 0.0)
	_lumiere(racine, Vector3(-224.0, 2.9, -58.0), 9.0)


static func _chambres(racine: Node3D) -> void:
	# Trois chambres de garde séparées par des cloisons basses
	for x in [-227.0, -221.0]:
		Geo.mur(racine, "z", x, -70.0, -65.0, 0.0, 2.2, 0.1, CLOISON)
	for i in 3:
		var x := -230.0 + i * 6.0
		_meuble(racine, Vector3(0.95, 0.45, 2.05), Vector3(x, 0.23, -68.7), Color(0.3, 0.3, 0.33), true)
		Lot.boite_c(Vector3(0.9, 0.12, 1.95), Vector3(x, 0.51, -68.7), Color(0.95, 0.95, 0.95))
		Lot.boite_c(Vector3(0.94, 0.06, 1.4), Vector3(x, 0.59, -68.35), MARINE)
		Lot.boite_c(Vector3(0.6, 0.1, 0.35), Vector3(x, 0.62, -69.45), Color(0.97, 0.97, 0.97))
		Lot.boite_c(Vector3(0.95, 0.8, 0.05), Vector3(x, 0.6, -69.75), Color(0.3, 0.3, 0.33))
		_meuble(racine, Vector3(0.45, 0.5, 0.4), Vector3(x + 0.85, 0.25, -69.5), BOIS)
		Lot.cylindre(0.08, 0.25, Vector3(x + 0.85, 0.62, -69.5), Geo.mat(Color(1.0, 0.95, 0.8), 0.6))
		_meuble(racine, Vector3(0.8, 1.9, 0.55), Vector3(x - 1.9, 0.95, -69.4), Color(0.6, 0.5, 0.38), true)
		Lot.boite_c(Vector3(1.3, 0.02, 0.8), Vector3(x, 0.14, -66.9), Color(0.55, 0.2, 0.18))
	_ecriteau(racine, "CHAMBRES", Vector3(-224.0, 2.55, -61.9), 0.0)
	_lumiere(racine, Vector3(-224.0, 2.9, -66.0), 9.0, 0.5)


# ---------------------------------------------------------------------------
# Remise des engins
# ---------------------------------------------------------------------------

static func _remise(racine: Node3D) -> void:
	# Râteliers de tuyaux roulés contre le mur de droite
	for r in 3:
		var z0 := -50.0 + r * 5.5
		for sz in [-2.2, 2.2]:
			Lot.boite_c(Vector3(0.5, 2.6, 0.06), Vector3(-215.5, 1.3, z0 + sz), ROUGE)
		for k in 3:
			var y := 0.5 + k * 0.8
			Lot.boite_c(Vector3(0.5, 0.04, 4.4), Vector3(-215.5, y - 0.3, z0), Color(0.3, 0.3, 0.32))
			for i in 8:
				var c := Color(0.92, 0.9, 0.85) if (i + k) % 3 != 0 else Color(0.85, 0.2, 0.15)
				var axe := Basis(Vector3.BACK, PI * 0.5)
				Lot.cylindre(0.26, 0.09, Vector3(-215.5, y, z0 - 1.93 + i * 0.55), Geo.mat(c), axe)
				Lot.cylindre(0.07, 0.1, Vector3(-215.5, y, z0 - 1.93 + i * 0.55), Geo.mat(Color(0.75, 0.75, 0.7)), axe)
		var col := StaticBody3D.new()
		col.position = Vector3(-215.5, 1.3, z0)
		racine.add_child(col)
		var cs := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = Vector3(0.6, 2.6, 4.5)
		cs.shape = forme
		col.add_child(cs)
	_ecriteau(racine, "TUYAUX DE RECHANGE", Vector3(-215.25, 3.1, -44.5), -PI * 0.5, ROUGE)
	# Pièces de jonction, lances et divisions sur un établi
	_meuble(racine, Vector3(0.8, 0.9, 3.0), Vector3(-215.6, 0.45, -31.0), Color(0.3, 0.32, 0.35), true)
	Lot.boite_c(Vector3(0.85, 0.05, 3.05), Vector3(-215.6, 0.92, -31.0), BOIS)
	for i in 5:
		Lot.cylindre(0.05, 0.5, Vector3(-215.6, 1.0, -32.2 + i * 0.6), Geo.mat(Color(0.75, 0.6, 0.25)), Basis(Vector3.RIGHT, PI * 0.5))
	Lot.boite_c(Vector3(0.05, 1.2, 3.0), Vector3(-215.22, 1.8, -31.0), Color(0.6, 0.62, 0.55))
	for i in 12:
		Lot.boite_c(Vector3(0.06, 0.06, 0.25), Vector3(-215.28, 1.4 + (1 if i >= 6 else 0) * 0.5, -32.3 + (i % 6) * 0.5), Color(0.2, 0.2, 0.22))
	# Étagères de matériel à gauche, près de la façade : cônes, triangles, caisses, rubalise
	_etagere(racine, Vector3(-284.4, 0, -22.0), PI * 0.5, 6.0, 0.6, 2.2, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for k in 4:
		for i in 7:
			var y := 0.15 + k * 0.67 + 0.02
			var c: Color = [Color(0.85, 0.15, 0.1), Color(0.2, 0.3, 0.6), Color(0.3, 0.3, 0.3), Color(0.55, 0.45, 0.3), Color(0.9, 0.6, 0.1)][rng.randi() % 5]
			var h := rng.randf_range(0.2, 0.4)
			Lot.boite_c(Vector3(0.45, h, rng.randf_range(0.4, 0.75)), Vector3(-284.4, y + h * 0.5, -24.6 + i * 0.75), c)
	for i in 6:
		for j in 4:
			Lot.cone(0.17, 0.5, Vector3(-283.4, 0.27 + j * 0.12, -17.0 + i * 0.42), Geo.mat(Color(0.95, 0.4, 0.05)))
		Lot.boite_c(Vector3(0.34, 0.03, 0.34), Vector3(-283.4, 0.02, -17.0 + i * 0.42), Color(0.1, 0.1, 0.1))
	# Brancard de rechange, bouteilles d'oxygène et chariot ARI près du VSAV
	Lot.boite_c(Vector3(0.6, 0.08, 2.0), Vector3(-266.8, 0.85, -48.0), Color(0.2, 0.45, 0.75))
	for dz in [-0.85, 0.85]:
		Lot.boite_c(Vector3(0.05, 0.8, 0.05), Vector3(-266.8, 0.42, -48.0 + dz), METAL)
	for i in 4:
		Lot.cylindre(0.08, 1.0, Vector3(-266.5 + i * 0.22, 0.5, -51.8), Geo.mat(Color(0.95, 0.95, 0.95)))
		Lot.cylindre(0.081, 0.18, Vector3(-266.5 + i * 0.22, 0.92, -51.8), Geo.mat(Color(0.2, 0.6, 0.3)))
	Lot.boite_c(Vector3(1.0, 0.05, 0.3), Vector3(-266.17, 0.8, -51.95), METAL)
	# Tableau des départs et horloge entre les portes
	_panneau(racine, "DÉPARTS / DISPONIBILITÉ", Vector3(-256.0, 1.7, -53.87), 0.0, 2.2, 1.2)
	Lot.boite_c(Vector3(1.5, 0.8, 0.05), Vector3(-245.0, 2.8, -53.87), Color(0.05, 0.05, 0.06))
	Lot.boite(Vector3(1.4, 0.7, 0.01), Vector3(-245.0, 2.8, -53.84), Tex.emissif(Color(0.15, 0.25, 0.5), 0.8))
	var ecran := Geo.texte(racine, "VSAV 1   DISPONIBLE\nFPT 1    DISPONIBLE\nVL CDG   DISPONIBLE", Vector3(-245.0, 2.8, -53.82), 14, Color(0.6, 1.0, 0.6), false)
	ecran.outline_size = 0
	# Extincteurs le long des murs
	for p in [Vector3(-284.6, 0, -30.0), Vector3(-284.6, 0, -50.0), Vector3(-215.45, 0, -24.0), Vector3(-270.0, 0, -14.4), Vector3(-230.0, 0, -14.4), Vector3(-252.0, 0, -53.75)]:
		_extincteur(p)
	# Poste de lavage : bac, tuyau d'arrosage enroulé
	Lot.boite_c(Vector3(1.4, 0.9, 0.6), Vector3(-232.0, 0.45, -53.6), Color(0.6, 0.62, 0.64))
	Lot.cylindre(0.3, 0.12, Vector3(-230.6, 1.3, -53.86), Geo.mat(Color(0.2, 0.5, 0.25)), Basis(Vector3.RIGHT, PI * 0.5))
	# Marquage au sol autour des emplacements et allée piétonne
	for px in [-262.0, -238.0]:
		for sx in [-2.3, 2.3]:
			Lot.boite_c(Vector3(0.12, 0.01, 11.0), Vector3(px + sx, 0.125, -38.0), JAUNE)
	for z in range(-52, -15, 2):
		Lot.boite_c(Vector3(1.2, 0.01, 0.4), Vector3(-250.0, 0.125, float(z)), Color(0.95, 0.95, 0.9))
	# Véhicule léger du chef de garde (rouge, gyrophares bleus sur le toit), garé à droite
	var pos := Vector3(-222.0, 0, -21.5)
	var h_toit := 1.52
	if Modeles.voiture(racine, "kodiaq", pos, PI, Color(0.72, 0.04, 0.03)) != null:
		# VL sur la base du SUV fourni : rampe bleue sur le toit et inscriptions jaunes
		h_toit = 1.72
		for cote in [-1.0, 1.0]:
			# Lettres d'environ 9 cm et 6 cm de haut, comme sur un vrai VL
			var tx := Geo.texte(racine, "SAPEURS-POMPIERS", pos + Vector3(cote * 0.97, 0.84, 0.3), 26, JAUNE, false)
			tx.rotation.y = cote * PI * 0.5
			tx.pixel_size = 0.0035
			tx.outline_size = 0
			var ch := Geo.texte(racine, "CHEF DE GARDE", pos + Vector3(cote * 0.97, 0.74, 0.3), 20, JAUNE, false)
			ch.rotation.y = cote * PI * 0.5
			ch.pixel_size = 0.0032
			ch.outline_size = 0
	else:
		VoitureModele.garer(Lot, "break", Color(0.72, 0.06, 0.05), pos, Basis(Vector3.UP, PI))
	Lot.boite_c(Vector3(1.1, 0.1, 0.25), pos + Vector3(0, h_toit, 0.2), Color(0.1, 0.1, 0.1))
	for sx in [-0.4, 0.4]:
		Lot.boite(Vector3(0.28, 0.1, 0.22), pos + Vector3(sx, h_toit + 0.08, 0.2), Tex.emissif(Color(0.2, 0.35, 1.0), 0.8))
	var corps := StaticBody3D.new()
	corps.position = pos + Vector3(0, 0.75, 0)
	racine.add_child(corps)
	var cs2 := CollisionShape3D.new()
	var f2 := BoxShape3D.new()
	f2.size = Vector3(1.8, 1.3, 4.6)
	cs2.shape = f2
	corps.add_child(cs2)
	Lot.boite_c(Vector3(3.0, 0.01, 5.6), Vector3(-222.0, 0.125, -21.5), Color(0.82, 0.82, 0.8))
	var marquage := Geo.texte(racine, "VL CDG", Vector3(-222.0, 0.13, -24.8), 40, JAUNE, false)
	marquage.rotation.x = -PI * 0.5
	_materiel_vl(racine)


## Matériel rangé autour du VL : armoire des lots, étagère de sacs, émulseur sur palette,
## dévidoir mobile, motopompe remorquable et réserve de balisage.
static func _materiel_vl(racine: Node3D) -> void:
	var gris := Color(0.42, 0.46, 0.5)
	var axe_x := Basis(Vector3.BACK, PI * 0.5)
	# Armoire métallique à deux portes contre le mur de droite
	_meuble(racine, Vector3(0.6, 2.0, 1.2), Vector3(-215.35, 1.0, -16.4), gris, true)
	Lot.boite_c(Vector3(0.01, 1.9, 0.02), Vector3(-215.66, 1.0, -16.4), Color(0.2, 0.2, 0.22))
	for dz in [-0.08, 0.08]:
		Lot.boite_c(Vector3(0.03, 0.2, 0.03), Vector3(-215.68, 1.1, -16.4 + dz), METAL)
	_ecriteau(racine, "LOTS", Vector3(-215.66, 1.75, -16.4), -PI * 0.5, ROUGE)
	# Étagère de sacs : lots de sauvetage, sacs d'oxygénothérapie, kits de balisage
	_etagere(racine, Vector3(-215.4, 0, -19.6), PI * 0.5, 3.0, 0.5, 2.0, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for k in 4:
		var y := 0.15 + k * 0.6 + 0.02
		var z := -20.9
		while z < -18.4:
			var l := rng.randf_range(0.4, 0.65)
			var h := rng.randf_range(0.22, 0.4)
			var c: Color = [Color(0.8, 0.1, 0.08), Color(0.85, 0.35, 0.05), Color(0.15, 0.3, 0.6), Color(0.2, 0.2, 0.22), Color(0.9, 0.85, 0.2)][rng.randi() % 5]
			Lot.boite_c(Vector3(0.42, h, l), Vector3(-215.4, y + h * 0.5, z + l * 0.5), c)
			Lot.boite_c(Vector3(0.43, 0.03, l * 0.6), Vector3(-215.4, y + h + 0.015, z + l * 0.5), Color(0.1, 0.1, 0.1))
			z += l + 0.08
	# Bidons d'émulseur sur palette
	Lot.boite_c(Vector3(0.8, 0.14, 1.2), Vector3(-215.7, 0.07, -22.6), BOIS)
	for i in 2:
		for j in 3:
			for k in 2:
				var p := Vector3(-215.9 + i * 0.4, 0.34 + k * 0.42, -23.0 + j * 0.4)
				Lot.boite_c(Vector3(0.34, 0.4, 0.3), p, Color(0.95, 0.85, 0.15))
				Lot.cylindre(0.04, 0.06, p + Vector3(0.08, 0.22, 0), Geo.mat(Color(0.1, 0.1, 0.1)))
	_collision(racine, Vector3(0.8, 1.0, 1.2), Vector3(-215.7, 0.5, -22.6))
	# Dévidoir mobile (tambour de tuyau sur deux grandes roues)
	var dv := Vector3(-216.3, 0, -26.6)
	for sx in [-0.42, 0.42]:
		Lot.cylindre(0.45, 0.08, dv + Vector3(sx, 0.45, 0), Geo.mat(Color(0.08, 0.08, 0.08)), axe_x)
		Lot.boite_c(Vector3(0.05, 1.0, 0.05), dv + Vector3(sx * 0.85, 0.75, 0), ROUGE)
	Lot.cylindre(0.38, 0.6, dv + Vector3(0, 0.6, 0), Geo.mat(Color(0.92, 0.9, 0.84)), axe_x)
	Lot.cylindre(0.4, 0.04, dv + Vector3(-0.31, 0.6, 0), Geo.mat(ROUGE), axe_x)
	Lot.cylindre(0.4, 0.04, dv + Vector3(0.31, 0.6, 0), Geo.mat(ROUGE), axe_x)
	Lot.boite_c(Vector3(0.05, 0.05, 1.0), dv + Vector3(-0.36, 0.9, -0.45), ROUGE, Basis(Vector3.RIGHT, 0.6))
	Lot.boite_c(Vector3(0.05, 0.05, 1.0), dv + Vector3(0.36, 0.9, -0.45), ROUGE, Basis(Vector3.RIGHT, 0.6))
	Lot.cylindre(0.03, 0.8, dv + Vector3(0, 1.2, -0.85), Geo.mat(Color(0.1, 0.1, 0.1)), axe_x)
	_collision(racine, Vector3(1.0, 1.2, 1.0), dv + Vector3(0, 0.6, 0))
	# Motopompe remorquable entre le VL et le FPT, timon vers la porte
	var mp := Vector3(-229.6, 0, -19.5)
	_meuble(racine, Vector3(1.1, 0.55, 1.7), mp + Vector3(0, 0.75, 0), ROUGE, true)
	Lot.boite_c(Vector3(0.95, 0.5, 1.0), mp + Vector3(0, 1.27, -0.2), Color(0.25, 0.27, 0.3))
	Lot.cylindre(0.2, 0.35, mp + Vector3(0, 1.15, 0.55), Geo.mat(Color(0.6, 0.62, 0.64)), axe_x)
	for sx in [-0.5, 0.5]:
		Lot.cylindre(0.11, 0.15, mp + Vector3(sx * 1.05, 1.15, 0.55), Geo.mat(Color(0.75, 0.6, 0.25)), axe_x)
	for sx in [-0.68, 0.68]:
		Lot.cylindre(0.3, 0.18, mp + Vector3(sx, 0.3, 0), Geo.mat(Color(0.08, 0.08, 0.08)), axe_x)
		Lot.cylindre(0.15, 0.19, mp + Vector3(sx, 0.3, 0), Geo.mat(METAL), axe_x)
		Lot.boite_c(Vector3(0.22, 0.05, 0.75), mp + Vector3(sx, 0.63, 0), ROUGE.darkened(0.3))
	Lot.boite_c(Vector3(0.08, 0.08, 1.3), mp + Vector3(0, 0.55, 1.45), Color(0.2, 0.2, 0.22))
	Lot.cylindre(0.08, 0.4, mp + Vector3(0, 0.35, 1.95), Geo.mat(METAL))
	Lot.cylindre(0.08, 0.05, mp + Vector3(0, 0.08, 1.95), Geo.mat(Color(0.1, 0.1, 0.1)), axe_x)
	# Tuyaux d'aspiration noirs rangés sur le côté
	for i in 2:
		Lot.cylindre(0.07, 1.6, mp + Vector3(-0.62 + i * 0.16, 1.1, -0.1), Geo.mat(Color(0.06, 0.06, 0.06)), Basis(Vector3.RIGHT, PI * 0.5))
	Lot.boite_c(Vector3(2.0, 0.01, 3.4), mp + Vector3(0, 0.125, 0.4), Color(0.82, 0.82, 0.8))
	var t := Geo.texte(racine, "MPR", mp + Vector3(0, 0.13, -1.0), 40, JAUNE, false)
	t.rotation.x = -PI * 0.5
	# Réserve de balisage : cônes empilés, panneaux triangulaires, barrières
	var rb := Vector3(-229.6, 0, -28.5)
	Lot.boite_c(Vector3(1.2, 0.14, 0.8), rb + Vector3(0, 0.07, 0), BOIS)
	for i in 3:
		for j in 2:
			for k in 5:
				Lot.cone(0.16, 0.5, rb + Vector3(-0.4 + i * 0.4, 0.4 + k * 0.1, -0.2 + j * 0.4), Geo.mat(Color(0.95, 0.4, 0.05)))
	for i in 3:
		var bt := Basis(Vector3.RIGHT, -0.15)
		Lot.boite_c(Vector3(0.8, 0.7, 0.03), rb + Vector3(0, 0.45, -0.7 - i * 0.06), Color(0.95, 0.95, 0.95), bt)
		Lot.boite_c(Vector3(0.6, 0.5, 0.032), rb + Vector3(0, 0.45, -0.7 - i * 0.06), ROUGE, bt)
	for i in 3:
		Lot.boite_c(Vector3(2.0, 0.12, 0.04), rb + Vector3(0, 0.95 - i * 0.04, 0.8 + i * 0.12), Color(0.95, 0.95, 0.95), Basis(Vector3.RIGHT, -0.05))
		for sx in [-0.95, 0.95]:
			Lot.boite_c(Vector3(0.05, 1.0, 0.05), rb + Vector3(sx, 0.5, 0.8 + i * 0.12), Color(0.85, 0.2, 0.1))
	_collision(racine, Vector3(2.2, 1.0, 2.2), rb + Vector3(0, 0.5, 0.2))
	_panneau(racine, "CONSIGNES VL CDG", Vector3(-215.0, 1.6, -28.2), -PI * 0.5, 1.4, 0.9)


static func _salle_de_sport(racine: Node3D) -> void:
	# Le long du mur de gauche, au fond de la remise
	Lot.boite_c(Vector3(4.0, 0.03, 22.0), Vector3(-282.6, 0.13, -42.0), Color(0.15, 0.2, 0.32))
	# Tapis de course
	for i in 2:
		var z := -52.0 + i * 2.2
		_meuble(racine, Vector3(0.8, 0.2, 1.8), Vector3(-282.6, 0.24, z), Color(0.12, 0.12, 0.12), true)
		Lot.boite_c(Vector3(0.55, 0.02, 1.6), Vector3(-282.6, 0.35, z), Color(0.05, 0.05, 0.05))
		for sx in [-0.38, 0.38]:
			Lot.boite_c(Vector3(0.05, 1.1, 0.05), Vector3(-282.6 + sx, 0.85, z + 0.8), METAL)
		Lot.boite_c(Vector3(0.8, 0.25, 0.15), Vector3(-282.6, 1.4, z + 0.85), Color(0.15, 0.15, 0.15))
		Lot.boite(Vector3(0.3, 0.12, 0.01), Vector3(-282.6, 1.42, z + 0.77), Tex.emissif(Color(0.3, 0.6, 1.0), 0.8))
	# Banc de musculation avec barre et disques
	var zb := -46.0
	_meuble(racine, Vector3(0.35, 0.45, 1.3), Vector3(-282.6, 0.23, zb), Color(0.1, 0.1, 0.12), true)
	Lot.boite_c(Vector3(0.36, 0.08, 1.2), Vector3(-282.6, 0.5, zb), ROUGE)
	for sx in [-0.55, 0.55]:
		Lot.boite_c(Vector3(0.06, 1.2, 0.06), Vector3(-282.6 + sx, 0.6, zb - 0.55), Color(0.2, 0.2, 0.22))
	Lot.cylindre(0.015, 1.8, Vector3(-282.6, 1.1, zb - 0.55), Geo.mat(METAL), Basis(Vector3.BACK, PI * 0.5))
	for sx in [-0.72, 0.72]:
		Lot.cylindre(0.22, 0.05, Vector3(-282.6 + sx, 1.1, zb - 0.55), Geo.mat(Color(0.08, 0.08, 0.08)), Basis(Vector3.BACK, PI * 0.5))
	# Râtelier d'haltères
	_meuble(racine, Vector3(0.5, 0.7, 2.0), Vector3(-284.4, 0.35, -42.0), Color(0.2, 0.2, 0.22), true)
	for i in 6:
		Lot.cylindre(0.012, 0.3, Vector3(-284.4, 0.76, -42.8 + i * 0.32), Geo.mat(METAL), Basis(Vector3.BACK, PI * 0.5))
		for sx in [-0.13, 0.13]:
			Lot.cylindre(0.05 + i * 0.006, 0.05, Vector3(-284.4 + sx, 0.76, -42.8 + i * 0.32), Geo.mat(Color(0.1, 0.1, 0.1)), Basis(Vector3.BACK, PI * 0.5))
	# Rameur
	Lot.boite_c(Vector3(0.3, 0.12, 2.2), Vector3(-282.6, 0.25, -38.5), Color(0.15, 0.15, 0.17))
	Lot.boite_c(Vector3(0.4, 0.08, 0.35), Vector3(-282.6, 0.4, -38.2), Color(0.1, 0.1, 0.1))
	Lot.cylindre(0.25, 0.12, Vector3(-282.6, 0.4, -39.6), Geo.mat(Color(0.12, 0.12, 0.14)), Basis(Vector3.BACK, PI * 0.5))
	# Sac de frappe suspendu et barre de traction
	Lot.boite_c(Vector3(0.06, 0.06, 1.6), Vector3(-283.5, 2.9, -35.0), Color(0.2, 0.2, 0.22))
	Lot.cylindre(0.2, 1.0, Vector3(-283.5, 2.05, -35.5), Geo.mat(Color(0.5, 0.08, 0.08)))
	Lot.cylindre(0.01, 0.4, Vector3(-283.5, 2.7, -35.5), Geo.mat(METAL))
	Lot.cylindre(0.02, 1.2, Vector3(-284.0, 2.3, -33.0), Geo.mat(METAL), Basis(Vector3.BACK, PI * 0.5))
	# Espalier
	Lot.boite_c(Vector3(0.08, 2.6, 0.08), Vector3(-284.6, 1.3, -32.0), BOIS)
	Lot.boite_c(Vector3(0.08, 2.6, 0.08), Vector3(-284.6, 1.3, -31.1), BOIS)
	for k in 10:
		Lot.cylindre(0.02, 0.9, Vector3(-284.55, 0.25 + k * 0.25, -31.55), Geo.mat(BOIS), Basis(Vector3.RIGHT, PI * 0.5))
	_ecriteau(racine, "SALLE DE SPORT", Vector3(-284.75, 3.0, -42.0), PI * 0.5, Color(0.15, 0.45, 0.25))
	_panneau(racine, "PLANNING SPORT", Vector3(-284.75, 1.6, -48.5), PI * 0.5, 1.2, 0.8)


# ---------------------------------------------------------------------------
# Extérieurs
# ---------------------------------------------------------------------------

static func _cour_et_tour(racine: Node3D) -> void:
	var bet: Material = Tex.mat_beton()
	# Cour de manœuvre derrière le bâtiment
	Geo.boite_mat(racine, Vector3(78.0, 0.06, 8.6), Vector3(-250.0, 0.09, -74.3), Tex.mat_asphalte(), false)
	for x in range(-280, -225, 6):
		Lot.boite_c(Vector3(3.0, 0.01, 0.15), Vector3(float(x), 0.125, -74.0), Color(0.95, 0.95, 0.9))
	# Tour de manœuvre : 5 niveaux de fenêtres, garde-corps, échelle à crochets accrochée
	var tx := -219.0
	var tz := -74.5
	Geo.boite_mat(racine, Vector3(4.0, 16.0, 4.0), Vector3(tx, 8.0, tz), bet)
	Geo.boite(racine, Vector3(4.3, 0.6, 4.3), Vector3(tx, 16.2, tz), ROUGE, false)
	for k in 5:
		var y := 2.2 + k * 3.0
		for face in 4:
			var b := Basis(Vector3.UP, face * PI * 0.5)
			Lot.boite_c(Vector3(1.4, 1.8, 0.05), Vector3(tx, y, tz) + b * Vector3(0, 0, 2.01), Color(0.06, 0.06, 0.07), b)
			Lot.boite_c(Vector3(1.6, 0.1, 0.25), Vector3(tx, y - 0.95, tz) + b * Vector3(0, 0, 2.1), ROUGE, b)
			Lot.boite_c(Vector3(0.08, 1.8, 0.08), Vector3(tx, y, tz) + b * Vector3(0.74, 0, 2.03), ROUGE, b)
			Lot.boite_c(Vector3(0.08, 1.8, 0.08), Vector3(tx, y, tz) + b * Vector3(-0.74, 0, 2.03), ROUGE, b)
		Lot.boite_c(Vector3(4.05, 0.12, 4.05), Vector3(tx, y - 1.4, tz), Color(0.75, 0.75, 0.72))
	# Échelle à crochets accrochée à la fenêtre du 1er étage (face vers la cour)
	for sx in [-0.17, 0.17]:
		Lot.boite_c(Vector3(0.05, 4.2, 0.06), Vector3(tx - 2.15, 2.8, tz + sx), Color(0.6, 0.45, 0.25), Basis(Vector3.BACK, -0.08))
	for k in 12:
		Lot.cylindre(0.015, 0.34, Vector3(tx - 2.15 - (k * 0.33 - 2.0) * 0.08, 0.9 + k * 0.33, tz), Geo.mat(METAL), Basis(Vector3.RIGHT, PI * 0.5))
	Geo.texte(racine, "TOUR DE MANŒUVRE", Vector3(tx, 17.0, tz), 60, Color(1, 0.9, 0.85))
	# Poteau incendie d'entraînement et dévidoir
	Lot.cylindre(0.12, 0.9, Vector3(-240.0, 0.45, -76.5), Geo.mat(ROUGE))
	Lot.sphere(0.13, Vector3(-240.0, 0.92, -76.5), Geo.mat(ROUGE))
	Lot.cylindre(0.05, 0.12, Vector3(-240.0, 0.6, -76.37), Geo.mat(METAL), Basis(Vector3.RIGHT, PI * 0.5))
	Lot.cylindre(0.45, 0.6, Vector3(-236.0, 0.55, -76.5), Geo.mat(Color(0.92, 0.9, 0.85)), Basis(Vector3.BACK, PI * 0.5))
	for sx in [-0.35, 0.35]:
		Lot.boite_c(Vector3(0.05, 1.1, 0.9), Vector3(-236.0 + sx, 0.55, -76.5), ROUGE)
	# Carcasse de voiture pour l'entraînement à la désincarcération
	VoitureModele.garer(Lot, "citadine", Color(0.4, 0.42, 0.38), Vector3(-262.0, 0, -75.0), Basis(Vector3.UP, PI * 0.5))
	Lot.boite_c(Vector3(4.6, 0.01, 2.6), Vector3(-262.0, 0.125, -75.0), Color(0.15, 0.15, 0.15))


static func _parking_personnel(racine: Node3D) -> void:
	# Bande d'enrobé le long du mur de droite, places en épi
	Geo.boite_mat(racine, Vector3(6.4, 0.06, 58.0), Vector3(-211.6, 0.09, -43.0), Tex.mat_asphalte(), false)
	var couleurs := [Color(0.15, 0.15, 0.17), Color(0.75, 0.76, 0.78), Color(0.2, 0.25, 0.45), Color(0.55, 0.1, 0.08), Color(0.9, 0.9, 0.9), Color(0.35, 0.35, 0.33)]
	var n := 0
	for i in 21:
		var z := -70.0 + i * 2.7
		Lot.boite_c(Vector3(4.8, 0.01, 0.1), Vector3(-211.6, 0.125, z), Color(0.95, 0.95, 0.9))
		if i == 20 or i % 4 == 3:
			continue
		var pos := Vector3(-211.6, 0, z + 1.35)
		var c: Color = couleurs[n % couleurs.size()]
		var ang := PI * 0.5 if n % 2 == 0 else -PI * 0.5
		# Voitures des modèles fournis, en alternance ; voiture dessinée en code si les fichiers manquent
		var type := "octavia" if n % 3 != 2 else "kodiaq"
		if Modeles.voiture(racine, type, pos, ang, c) == null and Modeles.voiture(racine, "octavia", pos, ang, c) == null:
			VoitureModele.garer(Lot, VoitureModele.TYPES[(n * 3) % VoitureModele.TYPES.size()], c, pos, Basis(Vector3.UP, ang))
		var corps := StaticBody3D.new()
		corps.position = pos + Vector3(0, 0.75, 0)
		racine.add_child(corps)
		var cs := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = Vector3(4.3, 1.3, 1.8)
		cs.shape = forme
		corps.add_child(cs)
		n += 1
	_ecriteau(racine, "PARKING DU PERSONNEL", Vector3(-211.6, 2.4, -14.5), 0.0, Color(0.1, 0.3, 0.6))
	Lot.boite_c(Vector3(0.08, 2.3, 0.08), Vector3(-211.6, 1.15, -14.6), METAL)
	# Poteau incendie accidenté (modèle scanné) dans la cour de manœuvre, pour l'entraînement
	Modeles.poser(racine, Modeles.POTEAU, Vector3(-226.0, 0, -80.0), 0.0, 0.075, "", false)
	# Poteau incendie devant la caserne
	Modeles.poser(racine, Modeles.RUE, Vector3(-292.0, 0, -11.0), 0.0, 1.0, Modeles.MOBILIER["poteau"], false)
	# Mât avec le drapeau français à l'entrée
	Lot.cylindre(0.05, 8.0, Vector3(-288.0, 4.0, -12.0), Geo.mat(Color(0.9, 0.9, 0.9)))
	var drapeau: Array = [Color(0.0, 0.14, 0.58), Color(0.97, 0.97, 0.97), Color(0.93, 0.16, 0.22)]
	for i in 3:
		Lot.boite_c(Vector3(0.4, 1.0, 0.02), Vector3(-287.75 + i * 0.4, 7.3, -12.0), drapeau[i])
