## Un engin de secours (VSAV ou FPT) conduit par un collègue IA.
## Il suit une liste de points, avec gyrophares et deux-tons.
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Son = preload("res://scripts/son.gd")
const Tex = preload("res://scripts/textures.gd")

signal arrive

var code := "VSAV"
var nom_complet := ""
var vitesse_max := 17.0
var vitesse := 0.0
var chemin: Array = []
var en_route := false
var sirene := false
var camera: Camera3D
var eau := 0.0
var eau_max := 0.0
var longueur := 6.5
var largeur := 2.4

var _gyros: Array = []
var _mats_gyro: Array = []
var _t := 0.0
var _son: AudioStreamPlayer3D


func construire(p_code: String) -> void:
	code = p_code
	var hauteur := 2.9
	if code == "FPT":
		longueur = 8.0
		largeur = 2.5
		hauteur = 3.2
		nom_complet = "Fourgon pompe-tonne"
		eau = 3000.0
		eau_max = 3000.0
	else:
		nom_complet = "Véhicule de secours et d'assistance aux victimes"
	var rouge: Material = Tex.carrosserie(Color(0.72, 0.03, 0.03))
	var blanc: Material = Tex.carrosserie(Color(0.95, 0.95, 0.95))
	var noir: Material = Tex.carrosserie(Color(0.06, 0.06, 0.07))
	var gris: Material = Tex.carrosserie(Color(0.55, 0.56, 0.58))
	var vitre: Material = Tex.vitre()
	var jaune: Material = Tex.emissif(Color(1.0, 0.82, 0.05), 0.15)
	# L'avant de l'engin est vers -z. Cabine à l'avant, cellule ou caisse à l'arrière.
	var cab_l := 2.3
	var caisse_l := longueur - cab_l
	var z_cab := -longueur * 0.5 + cab_l * 0.5
	var z_caisse := longueur * 0.5 - caisse_l * 0.5
	var sol := 0.55
	# Châssis et pare-chocs
	Geo.boite_mat(self, Vector3(largeur - 0.3, 0.35, longueur - 0.2), Vector3(0, sol, 0), noir, false)
	Geo.boite_mat(self, Vector3(largeur, 0.3, 0.25), Vector3(0, sol + 0.05, -longueur * 0.5 - 0.05), noir, false)
	# Cabine
	var h_cab := hauteur - 0.4 if code == "FPT" else hauteur - 0.6
	Geo.boite_mat(self, Vector3(largeur, h_cab - sol, cab_l), Vector3(0, sol + (h_cab - sol) * 0.5 + 0.15, z_cab), rouge, true)
	Geo.boite_mat(self, Vector3(largeur - 0.12, 0.85, 0.06), Vector3(0, h_cab - 0.45, -longueur * 0.5 - 0.01), vitre, false)
	for cote in [-1.0, 1.0]:
		Geo.boite_mat(self, Vector3(0.06, 0.75, cab_l - 0.5), Vector3(cote * (largeur * 0.5 + 0.005), h_cab - 0.5, z_cab + 0.05), vitre, false)
		# Rétroviseurs
		Geo.boite_mat(self, Vector3(0.08, 0.35, 0.22), Vector3(cote * (largeur * 0.5 + 0.3), h_cab - 0.6, -longueur * 0.5 + 0.35), noir, false)
		# Phares
		Geo.boite_mat(self, Vector3(0.45, 0.22, 0.05), Vector3(cote * (largeur * 0.5 - 0.4), sol + 0.55, -longueur * 0.5 - 0.02), Tex.emissif(Color(1, 1, 0.9), 0.6), false)
		# Feux arrière
		Geo.boite_mat(self, Vector3(0.25, 0.4, 0.05), Vector3(cote * (largeur * 0.5 - 0.25), sol + 0.6, longueur * 0.5 + 0.02), Tex.emissif(Color(0.9, 0.05, 0.05), 0.5), false)
	# Calandre
	Geo.boite_mat(self, Vector3(largeur * 0.6, 0.45, 0.04), Vector3(0, sol + 0.6, -longueur * 0.5 - 0.02), noir, false)
	# Caisse (cellule sanitaire du VSAV ou caisse à coffres du FPT)
	Geo.boite_mat(self, Vector3(largeur, hauteur - sol, caisse_l), Vector3(0, sol + (hauteur - sol) * 0.5 + 0.15, z_caisse), rouge, true)
	if code == "VSAV":
		# Bandes blanche et jaune, fenêtres de la cellule
		for cote in [-1.0, 1.0]:
			Geo.boite_mat(self, Vector3(0.02, 0.32, longueur - 0.3), Vector3(cote * (largeur * 0.5 + 0.01), 1.45, 0), blanc, false)
			Geo.boite_mat(self, Vector3(0.02, 0.12, longueur - 0.3), Vector3(cote * (largeur * 0.5 + 0.015), 1.2, 0), jaune, false)
			Geo.boite_mat(self, Vector3(0.03, 0.6, 1.0), Vector3(cote * (largeur * 0.5 + 0.01), 2.35, z_caisse + 0.6), vitre, false)
		# Portes arrière vitrées
		Geo.boite_mat(self, Vector3(largeur - 0.5, 0.6, 0.04), Vector3(0, 2.3, longueur * 0.5 + 0.01), vitre, false)
		Geo.boite_mat(self, Vector3(0.03, hauteur - sol - 0.2, 0.05), Vector3(0, sol + (hauteur - sol) * 0.5 + 0.15, longueur * 0.5 + 0.02), noir, false)
	else:
		# Coffres à rideaux sur les côtés, bande jaune, échelles et dévidoir
		var rideau: Material = Tex.plaque("rideau", Tex.rideau(), 0.5, 0.5)
		for cote in [-1.0, 1.0]:
			for k in 3:
				var zc: float = z_caisse - caisse_l * 0.5 + 0.35 + k * ((caisse_l - 0.7) / 3.0) + (caisse_l - 0.7) / 6.0
				Geo.boite_mat(self, Vector3(0.03, hauteur - sol - 0.9, (caisse_l - 0.7) / 3.0 - 0.15), Vector3(cote * (largeur * 0.5 + 0.01), sol + (hauteur - sol) * 0.5 + 0.35, zc), rideau, false)
			Geo.boite_mat(self, Vector3(0.02, 0.18, longueur - 0.3), Vector3(cote * (largeur * 0.5 + 0.02), sol + 0.45, 0), jaune, false)
		for xx in [-0.55, 0.55]:
			Geo.boite_mat(self, Vector3(0.08, 0.1, longueur - 1.0), Vector3(xx, hauteur + 0.3, 0.3), gris, false)
		for k in 12:
			Geo.boite_mat(self, Vector3(1.1, 0.05, 0.05), Vector3(0, hauteur + 0.3, -longueur * 0.5 + 1.2 + k * 0.55), gris, false)
		var devidoir: MeshInstance3D = Geo.cylindre(self, 0.45, 0.7, Vector3(0, sol + 1.0, longueur * 0.5 + 0.15), Color(0.25, 0.25, 0.27))
		devidoir.rotation.z = PI * 0.5
	# Chevrons arrière
	Geo.boite_mat(self, Vector3(largeur - 0.2, 0.35, 0.04), Vector3(0, sol + 0.3, longueur * 0.5 + 0.03), Tex.plaque("chevrons", Tex.chevrons(), 0.6, 0.6), false)
	# Roues avec jantes
	for zz in [-longueur * 0.32, longueur * 0.3]:
		for xx in [-largeur * 0.5 + 0.1, largeur * 0.5 - 0.1]:
			var r: MeshInstance3D = Geo.cylindre(self, 0.5, 0.38, Vector3(xx, 0.5, zz), Color(0.07, 0.07, 0.07))
			r.rotation.z = PI * 0.5
			var j: MeshInstance3D = Geo.cylindre(self, 0.28, 0.4, Vector3(xx, 0.5, zz), Color(0.7, 0.7, 0.72))
			j.rotation.z = PI * 0.5
	# Rampe de gyrophares bleus sur la cabine
	Geo.boite_mat(self, Vector3(largeur - 0.4, 0.12, 0.35), Vector3(0, h_cab + 0.21, z_cab - 0.3), noir, false)
	for xx in [-largeur * 0.32, largeur * 0.32]:
		var m: StandardMaterial3D = Tex.emissif(Color(0.15, 0.3, 1.0), 0.0)
		_mats_gyro.append(m)
		var g: Node3D = Geo.boite_mat(self, Vector3(0.6, 0.18, 0.3), Vector3(xx, h_cab + 0.36, z_cab - 0.3), m, false)
		var lum := OmniLight3D.new()
		lum.light_color = Color(0.2, 0.35, 1.0)
		lum.omni_range = 10.0
		lum.light_energy = 0.0
		g.add_child(lum)
		_gyros.append(lum)
	# Feux bleus à l'arrière
	for xx in [-largeur * 0.5 + 0.2, largeur * 0.5 - 0.2]:
		var m2: StandardMaterial3D = Tex.emissif(Color(0.15, 0.3, 1.0), 0.0)
		_mats_gyro.append(m2)
		Geo.boite_mat(self, Vector3(0.25, 0.25, 0.25), Vector3(xx, hauteur + 0.28, longueur * 0.5 - 0.2), m2, false)
	# Inscriptions
	for cote in [-1.0, 1.0]:
		var l: Label3D = Geo.texte(self, "SAPEURS-POMPIERS", Vector3(cote * (largeur * 0.5 + 0.04), 1.9 if code == "VSAV" else 2.4, z_caisse - 0.4), 64, Color.WHITE, false)
		l.rotation.y = cote * PI * 0.5
		l.outline_size = 0
		var l2: Label3D = Geo.texte(self, code + " · 18", Vector3(cote * (largeur * 0.5 + 0.04), h_cab - 1.3, z_cab), 44, Color.WHITE, false)
		l2.rotation.y = cote * PI * 0.5
		l2.outline_size = 0
	var avant_txt: Label3D = Geo.texte(self, "SAPEURS-POMPIERS", Vector3(0, h_cab - 0.95, -longueur * 0.5 - 0.05), 36, Color.WHITE, false)
	avant_txt.rotation.y = PI
	avant_txt.outline_size = 0
	# Caméra de poursuite (utilisée pendant les trajets)
	camera = Camera3D.new()
	camera.position = Vector3(0, 4.3, longueur * 0.5 + 8.0)
	camera.rotation_degrees.x = -11.0
	camera.far = 1500.0
	add_child(camera)
	_son = Son.new()
	_son.position = Vector3(0, 2, 0)
	add_child(_son)


func partir(points: Array, avec_sirene: bool) -> void:
	chemin = points.duplicate()
	en_route = chemin.size() > 0
	set_sirene(avec_sirene)


func set_sirene(v: bool) -> void:
	sirene = v
	_son.actif = v
	if not v:
		for l in _gyros:
			l.light_energy = 0.0
		for m in _mats_gyro:
			m.emission_energy_multiplier = 0.0


func garer(pos: Vector3, angle: float) -> void:
	global_position = pos
	rotation.y = angle
	en_route = false
	vitesse = 0.0
	chemin.clear()


func avant() -> Vector3:
	return -global_transform.basis.z


func droite() -> Vector3:
	return global_transform.basis.x


func _physics_process(delta: float) -> void:
	_t += delta
	if sirene:
		var phase := fmod(_t * 3.0, 1.0)
		if _gyros.size() == 2:
			_gyros[0].light_energy = 4.0 if phase < 0.5 else 0.0
			_gyros[1].light_energy = 0.0 if phase < 0.5 else 4.0
		for i in _mats_gyro.size():
			var allume: bool = (phase < 0.5) == (i % 2 == 0)
			_mats_gyro[i].emission_energy_multiplier = 6.0 if allume else 0.3
	if not en_route:
		return
	var cible: Vector3 = chemin[0]
	var vers: Vector3 = cible - global_position
	vers.y = 0.0
	var dist: float = vers.length()
	if dist < 1.5:
		chemin.pop_front()
		if chemin.is_empty():
			en_route = false
			vitesse = 0.0
			arrive.emit()
		return
	var angle_voulu: float = atan2(-vers.x, -vers.z)
	rotation.y = lerp_angle(rotation.y, angle_voulu, minf(1.0, delta * 2.5))
	# On ralentit avant un virage ou à l'arrivée.
	var v_cible := vitesse_max
	var ecart_angle: float = absf(angle_difference(rotation.y, angle_voulu))
	if ecart_angle > 0.4:
		v_cible = 6.0
	if chemin.size() == 1 and dist < 25.0:
		v_cible = maxf(3.0, dist * 0.5)
	elif chemin.size() > 1 and dist < 15.0:
		var suivant: Vector3 = chemin[1]
		var d2: Vector3 = (suivant - cible).normalized()
		if vers.normalized().dot(d2) < 0.7:
			v_cible = 8.0
	vitesse = move_toward(vitesse, v_cible, delta * (4.0 if v_cible > vitesse else 7.0))
	global_position += avant() * vitesse * delta
