## Corps humain commun à tous les personnages (pompiers, victimes, passants).
## Formes « sculptées » par sections effilées (cuisse plus large que le genou, taille plus fine
## que les épaules, mâchoire, nez…) plutôt que des boules et des capsules.
## Membres articulés (hanche, genou, cheville, épaule, coude) pour une marche naturelle.
## L'avant du personnage est vers -z, les pieds à y = 0.
##
##   var c = Corps.new(); add_child(c); c.construire(tenue)
##   tenue : dictionnaire (voir tenue_civile(), tenue_pompier())
##   c.animer(vitesse_m_s, delta)   c.allonger(true)   c.equiper(casque, ari)
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")

const PEAUX: Array = [Color(0.96, 0.82, 0.71), Color(0.89, 0.72, 0.6), Color(0.78, 0.6, 0.45), Color(0.6, 0.43, 0.31), Color(0.42, 0.29, 0.2)]
const CHEVEUX: Array = [Color(0.08, 0.06, 0.05), Color(0.25, 0.16, 0.09), Color(0.45, 0.3, 0.16), Color(0.75, 0.6, 0.38), Color(0.55, 0.53, 0.5), Color(0.85, 0.84, 0.82)]

static var _maillages: Dictionary = {}

var tenue: Dictionary = {}
var _hanches: Array = []
var _genoux: Array = []
var _epaules: Array = []
var _coudes: Array = []
var _bassin: Node3D
var _torse: Node3D
var _tete: Node3D
var _casque: Node3D
var _ari: Node3D
var _masque: Node3D
var _pas := 0.0
var _t := 0.0
var _allonge := false


# ---------------------------------------------------------------------------
# Tenues
# ---------------------------------------------------------------------------

## Tenue de ville tirée au hasard. age : en années, sexe : "M" ou "F".
static func tenue_civile(rng: RandomNumberGenerator, sexe: String, age: int) -> Dictionary:
	var hauts: Array = [Color(0.2, 0.3, 0.55), Color(0.72, 0.18, 0.18), Color(0.9, 0.9, 0.88), Color(0.22, 0.42, 0.3), Color(0.14, 0.14, 0.16),
		Color(0.85, 0.65, 0.22), Color(0.52, 0.4, 0.6), Color(0.45, 0.35, 0.25), Color(0.55, 0.6, 0.65), Color(0.85, 0.55, 0.55)]
	var bas: Array = [Color(0.14, 0.19, 0.33), Color(0.2, 0.2, 0.22), Color(0.45, 0.4, 0.32), Color(0.3, 0.3, 0.35), Color(0.32, 0.38, 0.5)]
	var chaussures: Array = [Color(0.1, 0.08, 0.07), Color(0.9, 0.9, 0.9), Color(0.35, 0.22, 0.14), Color(0.2, 0.2, 0.25)]
	var cheveux: Color = CHEVEUX[rng.randi() % 4]
	if age > 60:
		cheveux = CHEVEUX[4 + rng.randi() % 2]
	elif age > 45 and rng.randf() < 0.4:
		cheveux = CHEVEUX[4]
	var coiffure := "court"
	if sexe == "F":
		coiffure = ["long", "long", "chignon", "carre"][rng.randi() % 4]
	elif age > 50 and rng.randf() < 0.45:
		coiffure = "degarni"
	elif rng.randf() < 0.1:
		coiffure = "rase"
	var t := {
		"type": "civil", "sexe": sexe, "age": age,
		"peau": PEAUX[rng.randi() % PEAUX.size()], "cheveux": cheveux, "coiffure": coiffure,
		"haut": hauts[rng.randi() % hauts.size()], "bas": bas[rng.randi() % bas.size()],
		"chaussures": chaussures[rng.randi() % chaussures.size()],
		"manches_longues": rng.randf() < 0.6, "jupe": sexe == "F" and rng.randf() < 0.35,
		"veste": rng.randf() < 0.3, "veste_couleur": [Color(0.25, 0.2, 0.15), Color(0.15, 0.17, 0.2), Color(0.45, 0.4, 0.3)][rng.randi() % 3],
		"sac": rng.randf() < 0.25, "corpulence": rng.randf_range(0.92, 1.12) if age > 35 else rng.randf_range(0.9, 1.02),
		"taille": rng.randf_range(0.9, 0.98) if sexe == "F" else rng.randf_range(0.96, 1.05),
	}
	if age > 70:
		t["taille"] = float(t["taille"]) * 0.96
		t["manches_longues"] = true
	return t


## Tenue de sapeur-pompier : "f1" (tenue d'intervention bleu marine à bandes) ou "feu" (tenue de feu).
static func tenue_pompier(rng: RandomNumberGenerator, genre: String = "f1") -> Dictionary:
	var sexe := "F" if rng.randf() < 0.18 else "M"
	var t := tenue_civile(rng, sexe, rng.randi_range(22, 50))
	t["type"] = genre
	t["haut"] = Color(0.12, 0.15, 0.28) if genre == "f1" else Color(0.14, 0.16, 0.23)
	t["bas"] = t["haut"]
	t["chaussures"] = Color(0.05, 0.05, 0.05)
	t["manches_longues"] = true
	t["jupe"] = false
	t["veste"] = false
	t["sac"] = false
	if t["coiffure"] == "long":
		t["coiffure"] = "chignon"
	t["corpulence"] = rng.randf_range(0.97, 1.08)
	return t


# ---------------------------------------------------------------------------
# Maillages sculptés
# ---------------------------------------------------------------------------

## Volume défini par des sections horizontales : chaque anneau [y, demi-largeur x, demi-profondeur z, décalage z].
## Les sections sont reliées par des faces lisses, et le volume est fermé en haut et en bas.
static func loft(anneaux: Array, cotes: int = 10) -> ArrayMesh:
	var cle := str(anneaux) + "|" + str(cotes)
	if _maillages.has(cle):
		return _maillages[cle]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := anneaux.size()
	for i in n:
		var r: Array = anneaux[i]
		var y: float = r[0]
		var rx: float = r[1]
		var rz: float = r[2]
		var dz: float = r[3] if r.size() > 3 else 0.0
		# Pente de la paroi entre l'anneau précédent et le suivant (pour des normales justes)
		var a0: Array = anneaux[maxi(i - 1, 0)]
		var a1: Array = anneaux[mini(i + 1, n - 1)]
		var pente: float = 0.0
		var dy: float = float(a1[0]) - float(a0[0])
		if absf(dy) > 0.0001:
			pente = -((float(a1[1]) + float(a1[2])) - (float(a0[1]) + float(a0[2]))) * 0.5 / dy
		for j in cotes:
			var a: float = TAU * float(j) / float(cotes)
			var c: float = cos(a)
			var s: float = sin(a)
			var nm := Vector3(c / maxf(rx, 0.001), 0, s / maxf(rz, 0.001)).normalized()
			nm.y = pente
			st.set_normal(nm.normalized())
			st.set_uv(Vector2(float(j) / float(cotes), float(i) / float(n)))
			st.add_vertex(Vector3(rx * c, y, rz * s + dz))
	for i in n - 1:
		for j in cotes:
			var j2 := (j + 1) % cotes
			var av := i * cotes + j
			var bv := i * cotes + j2
			var cv := (i + 1) * cotes + j2
			var dv := (i + 1) * cotes + j
			st.add_index(av); st.add_index(bv); st.add_index(dv)
			st.add_index(bv); st.add_index(cv); st.add_index(dv)
	# Couvercles
	var haut: Array = anneaux[n - 1]
	var bas: Array = anneaux[0]
	var ih := n * cotes
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(0, float(haut[0]), float(haut[3]) if haut.size() > 3 else 0.0))
	st.set_normal(Vector3.DOWN)
	st.add_vertex(Vector3(0, float(bas[0]), float(bas[3]) if bas.size() > 3 else 0.0))
	for j in cotes:
		var j2 := (j + 1) % cotes
		st.add_index((n - 1) * cotes + j); st.add_index((n - 1) * cotes + j2); st.add_index(ih)
		st.add_index(j2); st.add_index(j); st.add_index(ih + 1)
	var m := st.commit()
	_maillages[cle] = m
	return m


func _piece(parent: Node3D, anneaux: Array, c: Color, pos: Vector3 = Vector3.ZERO, cotes: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = loft(anneaux, cotes)
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _mat(c: Color) -> Material:
	return Geo.mat(c)


func _noeud(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


## Anneau de tissu (bande réfléchissante, ceinture…) autour d'un membre.
func _bande(parent: Node3D, y: float, rx: float, rz: float, h: float, c: Color, dz: float = 0.0, cotes: int = 10) -> void:
	_piece(parent, [[y - h * 0.5, rx, rz, dz], [y + h * 0.5, rx, rz, dz]], c, Vector3.ZERO, cotes)


# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------

func construire(p_tenue: Dictionary) -> void:
	tenue = p_tenue
	var f: bool = tenue.get("sexe", "M") == "F"
	var k: float = tenue.get("corpulence", 1.0)
	scale = Vector3.ONE * float(tenue.get("taille", 1.0))
	var peau: Color = tenue["peau"]
	var haut: Color = tenue["haut"]
	var bas: Color = tenue["bas"]
	var pompier: bool = tenue["type"] != "civil"
	var feu: bool = tenue["type"] == "feu"
	var jaune := Color(0.95, 0.82, 0.1)
	var argent := Color(0.78, 0.8, 0.82)
	var lx_ep: float = (0.165 if f else 0.19) * k
	var lx_ha: float = (0.175 if f else 0.16) * k
	var hy := 0.93   # hauteur des hanches

	# --- Bassin (porte le tronc) et tronc ---
	_bassin = _noeud(self, Vector3(0, hy, 0))
	_piece(_bassin, [[-0.1, lx_ha * 0.82, 0.1 * k, 0.012], [-0.03, lx_ha, 0.118 * k, 0.018], [0.06, lx_ha * 0.95, 0.11 * k, 0.01], [0.12, (0.15 if f else 0.148) * k, 0.1 * k, 0.0]], bas)
	_torse = _noeud(_bassin, Vector3(0, 0.08, 0))
	var poitrine: float = -0.025 if f else -0.012
	_piece(_torse, [
		[0.0, (0.135 if f else 0.148) * k, 0.098 * k, 0.0],
		[0.12, (0.14 if f else 0.155) * k, 0.105 * k, -0.005],
		[0.24, (0.15 if f else 0.172) * k, 0.112 * k, poitrine],
		[0.33, lx_ep * 0.98, 0.112 * k, poitrine * 0.6],
		[0.4, lx_ep, 0.098 * k, 0.0],
		[0.445, lx_ep * 0.72, 0.075, 0.01],
		[0.47, 0.06, 0.05, 0.01],
	], haut, Vector3.ZERO, 12)
	# Cou
	_piece(_torse, [[0.44, 0.052, 0.05, 0.012], [0.56, 0.046, 0.048, 0.006]], peau, Vector3.ZERO, 8)
	if tenue.get("veste", false):
		var v: Color = tenue["veste_couleur"]
		_piece(_torse, [[-0.12, lx_ha * 1.05, 0.125 * k, 0.015], [0.0, 0.155 * k, 0.108 * k, 0.0], [0.24, 0.178 * k, 0.12 * k, -0.012], [0.4, lx_ep * 1.04, 0.105 * k, 0.0], [0.44, lx_ep * 0.75, 0.08, 0.01]], v, Vector3.ZERO, 12)
	if tenue.get("sac", false):
		var sac := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.28, 0.36, 0.12)
		sac.mesh = bm
		sac.material_override = _mat(Color(0.2, 0.22, 0.28))
		sac.position = Vector3(0, 0.25, 0.115 * k + 0.06)
		_torse.add_child(sac)

	# --- Tête ---
	_tete = _noeud(_torse, Vector3(0, 0.55, 0.008))
	_construire_tete(peau, f)
	if pompier:
		_details_pompier(feu, jaune, argent, lx_ep, lx_ha, k)

	# --- Jambes ---
	for cote in [-1.0, 1.0]:
		var hanche := _noeud(self, Vector3(cote * lx_ha * 0.55, hy, 0))
		var jupe: bool = tenue.get("jupe", false)
		var couleur_cuisse: Color = peau if jupe else bas
		_piece(hanche, [[0.02, 0.078 * k, 0.085 * k, 0.005], [-0.12, 0.072 * k, 0.077 * k, 0.0], [-0.3, 0.058 * k, 0.062 * k, -0.004], [-0.43, 0.047, 0.052, -0.008]], couleur_cuisse)
		var genou := _noeud(hanche, Vector3(0, -0.43, 0))
		var couleur_tibia: Color = peau if jupe else bas
		_piece(genou, [[0.02, 0.048, 0.052, -0.006], [-0.1, 0.052, 0.058, 0.012], [-0.24, 0.042, 0.045, 0.006], [-0.39, 0.031, 0.034, 0.0], [-0.42, 0.03, 0.032, 0.0]], couleur_tibia)
		if pompier:
			_bande(genou, -0.27, 0.046, 0.049, 0.045, jaune)
			_bande(genou, -0.31, 0.045, 0.048, 0.025, argent)
		# Pied / chaussure (posé à plat, pointe vers -z)
		var cheville := _noeud(genou, Vector3(0, -0.43, 0))
		var chaussure: Color = tenue["chaussures"]
		var p := _piece(cheville, [[-0.05, 0.043, 0.035, 0.035], [0.0, 0.048, 0.045, 0.045], [0.1, 0.05, 0.04, 0.04], [0.19, 0.048, 0.032, 0.032], [0.23, 0.035, 0.022, 0.022]], chaussure, Vector3(0, -0.07, 0.02), 8)
		p.rotation.x = -PI * 0.5
		if pompier:
			# Rangers montantes
			_piece(cheville, [[-0.06, 0.042, 0.045, 0.004], [0.08, 0.036, 0.04, 0.0]], chaussure)
		_hanches.append(hanche)
		_genoux.append(genou)
	if tenue.get("jupe", false):
		_piece(_bassin, [[-0.42, lx_ha * 1.3, 0.16 * k, 0.01], [-0.2, lx_ha * 1.15, 0.14 * k, 0.015], [0.0, lx_ha * 1.02, 0.12 * k, 0.015], [0.08, lx_ha * 0.95, 0.11 * k, 0.01]], bas, Vector3.ZERO, 12)

	# --- Bras ---
	for cote in [-1.0, 1.0]:
		var epaule := _noeud(_torse, Vector3(cote * (lx_ep - 0.035), 0.39, 0.005))
		epaule.rotation.z = cote * 0.06
		var manche: Color = haut
		if tenue.get("veste", false):
			manche = tenue["veste_couleur"]
		_piece(epaule, [[0.03, 0.052 * k, 0.055 * k, 0.0], [-0.04, 0.056 * k, 0.056 * k, 0.0], [-0.17, 0.046 * k, 0.048 * k, 0.003], [-0.29, 0.038, 0.04, 0.0]], manche, Vector3.ZERO, 8)
		var coude := _noeud(epaule, Vector3(0, -0.29, 0))
		var longues: bool = tenue.get("manches_longues", true)
		var avant_bras: Color = manche if longues else peau
		_piece(coude, [[0.02, 0.038, 0.04, 0.0], [-0.06, 0.042, 0.043, -0.003], [-0.2, 0.031, 0.027, 0.0], [-0.25, 0.028, 0.024, 0.0]], avant_bras, Vector3.ZERO, 8)
		if not longues:
			_bande(epaule, -0.16, 0.05 * k, 0.052 * k, 0.07, manche)
		if pompier:
			_bande(coude, -0.12, 0.04, 0.039, 0.04, jaune)
			_bande(coude, -0.155, 0.038, 0.036, 0.022, argent)
		# Main (paume vers l'intérieur), pouce
		var gants: bool = feu
		var cm: Color = Color(0.06, 0.06, 0.07) if gants else peau
		var main := _noeud(coude, Vector3(0, -0.255, 0))
		_piece(main, [[0.0, 0.022, 0.035, 0.0], [-0.05, 0.02, 0.045, 0.004], [-0.11, 0.016, 0.04, 0.006], [-0.16, 0.012, 0.028, 0.008]], cm, Vector3.ZERO, 8)
		var pouce := _piece(main, [[0.0, 0.012, 0.012, 0.0], [-0.06, 0.01, 0.01, 0.0]], cm, Vector3(-cote * 0.005, -0.03, -0.035), 6)
		pouce.rotation.x = 0.5
		_epaules.append(epaule)
		_coudes.append(coude)
		epaule.rotation.x = 0.0
		coude.rotation.x = 0.12


func _construire_tete(peau: Color, f: bool) -> void:
	var lx: float = 0.072 if f else 0.077
	# Crâne et visage : mâchoire plus étroite, pommettes, front
	_piece(_tete, [
		[0.0, 0.042, 0.048, 0.0],
		[0.02, 0.052, 0.062, -0.012],
		[0.045, lx * 0.85, 0.085, -0.01],
		[0.08, lx * 0.95, 0.095, -0.004],
		[0.12, lx, 0.1, 0.0],
		[0.165, lx * 1.01, 0.1, 0.003],
		[0.2, lx * 0.93, 0.092, 0.006],
		[0.225, lx * 0.72, 0.072, 0.008],
		[0.24, lx * 0.35, 0.035, 0.008],
	], peau, Vector3.ZERO, 12)
	var sombre := Color(0.07, 0.06, 0.06)
	var blanc := Color(0.92, 0.92, 0.9)
	# Nez
	var nez := _piece(_tete, [[0.0, 0.012, 0.01, 0.0], [0.045, 0.008, 0.006, 0.005]], peau.darkened(0.05), Vector3(0, 0.085, -0.098), 6)
	nez.rotation.x = 0.35
	# Yeux, sourcils, bouche, oreilles
	var cheveux: Color = tenue["cheveux"]
	for cote in [-1.0, 1.0]:
		_boite(_tete, Vector3(0.022, 0.011, 0.006), Vector3(cote * 0.03, 0.128, -0.1015), blanc)
		_boite(_tete, Vector3(0.01, 0.01, 0.006), Vector3(cote * 0.03, 0.128, -0.1045), sombre)
		_boite(_tete, Vector3(0.03, 0.007, 0.01), Vector3(cote * 0.031, 0.147, -0.103), cheveux.darkened(0.2))
		_boite(_tete, Vector3(0.016, 0.045, 0.03), Vector3(cote * (lx + 0.003), 0.115, 0.01), peau.darkened(0.04))
	_boite(_tete, Vector3(0.036, 0.007, 0.008), Vector3(0, 0.052, -0.098), peau.darkened(0.3))
	# Cheveux
	var c: Color = cheveux
	match tenue.get("coiffure", "court"):
		"court":
			_piece(_tete, [[0.13, lx * 1.06, 0.105, 0.012], [0.19, lx * 1.0, 0.1, 0.008], [0.225, lx * 0.8, 0.08, 0.008], [0.25, lx * 0.38, 0.04, 0.01]], c, Vector3.ZERO, 12)
			_piece(_tete, [[0.06, lx * 0.92, 0.07, 0.03], [0.14, lx * 1.05, 0.085, 0.025]], c, Vector3.ZERO, 10)
		"rase":
			_piece(_tete, [[0.15, lx * 1.02, 0.1, 0.006], [0.21, lx * 0.94, 0.094, 0.007], [0.235, lx * 0.6, 0.06, 0.008]], c.lerp(peau, 0.4), Vector3.ZERO, 12)
		"degarni":
			_piece(_tete, [[0.07, lx * 0.95, 0.075, 0.03], [0.16, lx * 1.04, 0.085, 0.028]], c, Vector3.ZERO, 10)
		"long", "carre", "chignon":
			_piece(_tete, [[0.13, lx * 1.08, 0.106, 0.012], [0.19, lx * 1.03, 0.102, 0.008], [0.23, lx * 0.82, 0.082, 0.008], [0.255, lx * 0.4, 0.042, 0.01]], c, Vector3.ZERO, 12)
			var bas_cheveux: float = -0.12 if tenue["coiffure"] == "long" else 0.02
			if tenue["coiffure"] != "chignon":
				_piece(_tete, [[bas_cheveux, lx * 1.15, 0.06, 0.06], [0.06, lx * 1.12, 0.075, 0.04], [0.15, lx * 1.08, 0.09, 0.02]], c, Vector3.ZERO, 10)
			else:
				_piece(_tete, [[0.05, lx * 0.95, 0.07, 0.03], [0.14, lx * 1.06, 0.088, 0.024]], c, Vector3.ZERO, 10)
				_piece(_tete, [[0.0, 0.03, 0.03, 0.0], [0.035, 0.042, 0.04, 0.0], [0.07, 0.028, 0.028, 0.0]], c, Vector3(0, 0.12, 0.1), 8)
	# Rides et barbe éventuelles
	if tenue.get("sexe", "M") == "M" and int(tenue.get("age", 30)) > 25 and hash(tenue["peau"]) % 4 == 0:
		_piece(_tete, [[0.0, 0.045, 0.052, -0.004], [0.03, 0.058, 0.068, -0.012], [0.06, lx * 0.9, 0.085, -0.006]], c.darkened(0.1), Vector3.ZERO, 12)


func _boite(parent: Node3D, taille: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = taille
	mi.mesh = bm
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


## Bandes réfléchissantes, inscriptions, ceinturon, casque F1, appareil respiratoire.
func _details_pompier(feu: bool, jaune: Color, argent: Color, lx_ep: float, lx_ha: float, k: float) -> void:
	var haut: Color = tenue["haut"]
	if feu:
		# Veste de feu longue (jusqu'à mi-cuisse), col montant, larges bandes
		_piece(_torse, [[-0.33, lx_ha * 1.28, 0.15 * k, 0.012], [-0.12, lx_ha * 1.18, 0.135 * k, 0.012], [0.05, 0.168 * k, 0.12 * k, 0.0], [0.25, 0.185 * k, 0.125 * k, -0.012], [0.4, lx_ep * 1.06, 0.11 * k, 0.0], [0.45, lx_ep * 0.75, 0.085, 0.01]], haut, Vector3.ZERO, 12)
		_piece(_torse, [[0.42, 0.07, 0.07, 0.01], [0.53, 0.062, 0.062, 0.01]], haut, Vector3.ZERO, 10)
		for y in [-0.27, 0.04, 0.3]:
			var bx: float = lx_ha * 1.3 if y < 0.0 else (0.19 * k if y > 0.2 else 0.175 * k)
			var bz: float = 0.152 * k if y < 0.0 else (0.132 * k if y > 0.2 else 0.127 * k)
			var bd: float = 0.012 if y < 0.0 else (-0.012 if y > 0.2 else 0.0)
			_bande(_torse, y, bx, bz, 0.05, jaune, bd, 12)
			_bande(_torse, y - 0.04, bx, bz, 0.025, argent, bd, 12)
	else:
		# Veste F1 : deux bandes jaune et gris sur la poitrine et le dos, ceinturon
		var bx2: float = maxf(0.18 * k, lx_ep * 1.0) + 0.006
		_bande(_torse, 0.28, bx2, 0.121 * k, 0.045, jaune, -0.012, 12)
		_bande(_torse, 0.245, bx2 - 0.003, 0.12 * k, 0.022, argent, -0.012, 12)
		_bande(_bassin, 0.09, lx_ha * 0.99, 0.113 * k, 0.04, Color(0.05, 0.05, 0.05), 0.01, 10)
		_boite(_bassin, Vector3(0.06, 0.035, 0.01), Vector3(0, 0.085, -0.115 * k), argent)
	var dos := Label3D.new()
	dos.text = "SAPEURS-POMPIERS"
	dos.font_size = 24
	dos.pixel_size = 0.0028
	dos.modulate = Color(0.9, 0.9, 0.9) if not feu else jaune
	dos.outline_size = 0
	dos.double_sided = false
	dos.position = Vector3(0, 0.33 if not feu else 0.16, (0.122 if not feu else 0.142) * k + 0.004)
	_torse.add_child(dos)
	# Casque F1 (blanc nacré, visière dorée relevée, couvre-nuque pour le feu)
	_casque = Node3D.new()
	_casque.position = Vector3(0, 0.0, 0.0)
	var casque_mat := Tex.carrosserie(Color(0.9, 0.91, 0.93))
	var coque := MeshInstance3D.new()
	coque.mesh = loft([[0.15, 0.094, 0.12, 0.014], [0.185, 0.097, 0.122, 0.008], [0.225, 0.09, 0.112, 0.006], [0.262, 0.068, 0.085, 0.008], [0.29, 0.032, 0.04, 0.008], [0.297, 0.005, 0.005, 0.008]], 14)
	coque.material_override = casque_mat
	_casque.add_child(coque)
	var crete := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.025, 0.02, 0.2)
	crete.mesh = bm
	crete.material_override = casque_mat
	crete.position = Vector3(0, 0.287, 0.005)
	_casque.add_child(crete)
	var visiere := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.16, 0.06, 0.01)
	visiere.mesh = vm
	var vmat := StandardMaterial3D.new()
	vmat.albedo_color = Color(0.85, 0.65, 0.15, 0.7)
	vmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vmat.metallic = 0.9
	vmat.roughness = 0.1
	visiere.material_override = vmat
	visiere.position = Vector3(0, 0.245, -0.11)
	visiere.rotation.x = -0.5
	_casque.add_child(visiere)
	var bande_casque := MeshInstance3D.new()
	bande_casque.mesh = loft([[0.195, 0.098, 0.124, 0.007], [0.21, 0.097, 0.122, 0.007]], 14)
	bande_casque.material_override = Tex.emissif(Color(0.95, 0.85, 0.2), 0.05)
	_casque.add_child(bande_casque)
	if feu:
		var nuque := MeshInstance3D.new()
		nuque.mesh = loft([[0.03, 0.085, 0.03, 0.1], [0.16, 0.09, 0.035, 0.095]], 10)
		nuque.material_override = _mat(haut.darkened(0.2))
		_casque.add_child(nuque)
	_tete.add_child(_casque)
	_casque.visible = false
	# Appareil respiratoire isolant (dossard, bouteille, sangles) et masque
	_ari = Node3D.new()
	_torse.add_child(_ari)
	var noir := Color(0.06, 0.06, 0.07)
	_boite(_ari, Vector3(0.22, 0.5, 0.04), Vector3(0, 0.15, 0.13 * k + 0.02), noir)
	var bouteille := MeshInstance3D.new()
	bouteille.mesh = loft([[-0.02, 0.07, 0.07, 0.0], [0.0, 0.085, 0.085, 0.0], [0.52, 0.085, 0.085, 0.0], [0.58, 0.05, 0.05, 0.0], [0.62, 0.02, 0.02, 0.0]], 14)
	bouteille.material_override = Tex.carrosserie(Color(0.95, 0.75, 0.1))
	bouteille.position = Vector3(0, -0.12, 0.13 * k + 0.12)
	_ari.add_child(bouteille)
	for cote in [-1.0, 1.0]:
		var sangle := _boite(_ari, Vector3(0.05, 0.42, 0.012), Vector3(cote * 0.09, 0.22, -0.112 * k), noir)
		sangle.rotation.x = 0.05
		_boite(_ari, Vector3(0.05, 0.03, 0.26 * k), Vector3(cote * 0.09, 0.42, 0.0), noir)
	_bande(_ari, -0.06, lx_ha * 1.05 if not feu else lx_ha * 1.3, 0.13 * k if not feu else 0.155 * k, 0.05, noir, 0.01)
	_ari.visible = false
	_masque = Node3D.new()
	_tete.add_child(_masque)
	var masque := MeshInstance3D.new()
	masque.mesh = loft([[0.0, 0.05, 0.03, -0.09], [0.05, 0.075, 0.04, -0.1], [0.14, 0.078, 0.04, -0.095], [0.19, 0.06, 0.035, -0.088]], 12)
	masque.material_override = _mat(noir)
	_masque.add_child(masque)
	var ecran := MeshInstance3D.new()
	ecran.mesh = loft([[0.06, 0.06, 0.02, -0.132], [0.17, 0.055, 0.02, -0.125]], 12)
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.6, 0.7, 0.75, 0.45)
	em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	em.metallic = 0.5
	em.roughness = 0.05
	ecran.material_override = em
	_masque.add_child(ecran)
	_cyl_simple(_masque, 0.028, 0.05, Vector3(0, 0.03, -0.14), noir).rotation.x = PI * 0.5
	_masque.visible = false


func _cyl_simple(parent: Node3D, r: float, h: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = loft([[-h * 0.5, r, r, 0.0], [h * 0.5, r, r, 0.0]], 10)
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


## Casque F1 sur la tête, appareil respiratoire sur le dos (masque sur le visage).
func equiper(casque: bool, ari: bool) -> void:
	if _casque != null:
		_casque.visible = casque or ari
	if _ari != null:
		_ari.visible = ari
		_masque.visible = ari


## Allongé sur le dos (tête vers -z), ou debout.
func allonger(v: bool) -> void:
	_allonge = v
	if v:
		# Bras le long du corps, jambes tendues, légère rotation de la tête
		rotation_order = EULER_ORDER_YXZ
		rotation = Vector3(PI * 0.5, PI, 0)
		position.y = 0.13
		for e in _epaules:
			e.rotation.x = 0.05
		for c in _coudes:
			c.rotation.x = 0.15
		_tete.rotation.y = 0.25
	else:
		rotation = Vector3.ZERO
		position.y = 0.0


## Animation : marche (ou course au-delà de 3 m/s) quand vitesse > 0, respiration au repos.
func animer(vitesse: float, delta: float) -> void:
	_t += delta
	if _allonge:
		# Respiration visible : la poitrine se soulève
		_torse.scale = Vector3(1.0, 1.0, 1.0 + sin(_t * 1.6) * 0.03)
		return
	var course: bool = vitesse > 3.0
	if vitesse > 0.05:
		_pas += delta * (vitesse * (2.6 if course else 3.6) + 1.2)
	else:
		_pas = move_toward(_pas, round(_pas / PI) * PI, delta * 5.0)
	var amp: float = clampf(vitesse / 1.4, 0.0, 1.0) * (1.25 if course else 1.0)
	var s: float = sin(_pas)
	for i in 2:
		var phase: float = _pas + (0.0 if i == 0 else PI)
		var si: float = sin(phase)
		var ci: float = cos(phase)
		_hanches[i].rotation.x = si * 0.42 * amp
		# Le genou plie pendant que la jambe revient vers l'avant
		_genoux[i].rotation.x = -(maxf(0.0, ci) * (0.75 if not course else 1.25) + 0.05) * amp
		_epaules[i].rotation.x = -si * 0.35 * amp
		_coudes[i].rotation.x = 0.15 + (0.25 + maxf(0.0, -si) * 0.3) * amp + (0.9 if course else 0.0) * amp
	# Le bassin monte et descend, le buste tourne un peu, la tête reste stable
	_bassin.position.y = 0.93 + absf(cos(_pas)) * 0.025 * amp - 0.012 * amp
	_bassin.rotation.y = s * 0.07 * amp
	_torse.rotation.y = -s * 0.1 * amp
	_torse.rotation.x = 0.06 * amp if course else 0.015 * amp
	# Respiration et léger balancement au repos
	var repos: float = 1.0 - clampf(amp, 0.0, 1.0)
	_torse.scale = Vector3(1.0, 1.0 + sin(_t * 1.7) * 0.006 * repos, 1.0 + sin(_t * 1.7) * 0.02 * repos)
	_tete.rotation.y = sin(_t * 0.37) * 0.25 * repos
	for i in 2:
		if repos > 0.5:
			_epaules[i].rotation.z = (-1.0 if i == 0 else 1.0) * (0.04 + sin(_t * 1.7) * 0.01)
