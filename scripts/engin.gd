## Un engin de secours (VSAV ou FPT) conduit par un collègue IA.
## Il suit une liste de points, avec gyrophares et deux-tons.
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Son = preload("res://scripts/son.gd")

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
var _t := 0.0
var _son: AudioStreamPlayer3D


func construire(p_code: String) -> void:
	code = p_code
	var rouge := Color(0.78, 0.06, 0.05)
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
	# L'avant de l'engin est vers -z.
	var cab_l := 2.2
	Geo.boite(self, Vector3(largeur, hauteur - 0.5, longueur - cab_l), Vector3(0, 0.5 + (hauteur - 0.5) * 0.5, cab_l * 0.5), rouge)
	Geo.boite(self, Vector3(largeur, hauteur - 0.9, cab_l), Vector3(0, 0.5 + (hauteur - 0.9) * 0.5, -(longueur - cab_l) * 0.5), rouge)
	# Pare-brise
	Geo.boite(self, Vector3(largeur - 0.2, 0.8, 0.05), Vector3(0, hauteur - 0.85, -longueur * 0.5 - 0.01), Color(0.2, 0.3, 0.4), false)
	# Bandes rétro-réfléchissantes
	if code == "VSAV":
		Geo.boite(self, Vector3(largeur + 0.02, 0.25, longueur - 0.4), Vector3(0, 1.2, 0), Color(0.95, 0.95, 0.95), false)
	else:
		Geo.boite(self, Vector3(largeur + 0.02, 0.2, longueur - 0.4), Vector3(0, 1.0, 0), Color(0.95, 0.85, 0.1), false)
		# Échelle sur le toit
		Geo.boite(self, Vector3(0.6, 0.15, longueur - 1.5), Vector3(0.5, hauteur + 0.1, 0.6), Color(0.75, 0.75, 0.78), false)
	# Roues
	for zz in [-longueur * 0.32, longueur * 0.32]:
		for xx in [-largeur * 0.5, largeur * 0.5]:
			var r: MeshInstance3D = Geo.cylindre(self, 0.5, 0.35, Vector3(xx, 0.5, zz), Color(0.08, 0.08, 0.08))
			r.rotation.z = PI * 0.5
	# Gyrophares bleus
	for xx in [-largeur * 0.3, largeur * 0.3]:
		var g: Node3D = Geo.boite(self, Vector3(0.35, 0.18, 0.3), Vector3(xx, hauteur - 0.3, -(longueur - cab_l) * 0.5), Color(0.2, 0.35, 1.0), false)
		var lum := OmniLight3D.new()
		lum.light_color = Color(0.2, 0.35, 1.0)
		lum.omni_range = 9.0
		lum.light_energy = 0.0
		g.add_child(lum)
		_gyros.append(lum)
	# Inscriptions sur les flancs
	for cote in [-1.0, 1.0]:
		var l: Label3D = Geo.texte(self, code, Vector3(cote * (largeur * 0.5 + 0.03), 1.8, 0.6), 90, Color.WHITE, false)
		l.rotation.y = cote * PI * 0.5
	Geo.texte(self, code + " Joué", Vector3(0, hauteur + 0.9, 0), 40, Color(1, 0.9, 0.6))
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
