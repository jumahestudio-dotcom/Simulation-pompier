## Un passant : il fait des allers-retours sur un trottoir, s'arrête de temps en temps
## et s'immobilise quand un engin passe tout près.
extends Node3D

const Geo = preload("res://scripts/geo.gd")

var depart := Vector3.ZERO
var arrivee := Vector3.ZERO
var monde = null
var vitesse := 1.3
var _vers_arrivee := true
var _pause := 0.0
var _pas := 0.0
var _jambes: Array = []
var _bras: Array = []

const HAUTS: Array = [Color(0.2, 0.3, 0.55), Color(0.75, 0.2, 0.2), Color(0.9, 0.9, 0.88), Color(0.2, 0.45, 0.3), Color(0.15, 0.15, 0.17), Color(0.85, 0.65, 0.2), Color(0.55, 0.4, 0.6), Color(0.45, 0.35, 0.25)]
const BAS: Array = [Color(0.15, 0.2, 0.35), Color(0.2, 0.2, 0.22), Color(0.45, 0.4, 0.32), Color(0.3, 0.3, 0.35)]
const PEAUX: Array = [Color(0.95, 0.8, 0.68), Color(0.8, 0.6, 0.45), Color(0.55, 0.38, 0.27), Color(0.35, 0.24, 0.17)]
const CHEVEUX: Array = [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.75, 0.6, 0.35), Color(0.6, 0.6, 0.6)]


func construire(rng: RandomNumberGenerator) -> void:
	var haut: Color = HAUTS[rng.randi() % HAUTS.size()]
	var bas: Color = BAS[rng.randi() % BAS.size()]
	var peau: Color = PEAUX[rng.randi() % PEAUX.size()]
	var taille := rng.randf_range(0.9, 1.05)
	scale = Vector3.ONE * taille
	vitesse = rng.randf_range(1.0, 1.6)
	for cote in [-0.12, 0.12]:
		var hanche := Node3D.new()
		hanche.position = Vector3(cote, 0.9, 0)
		add_child(hanche)
		Geo.boite(hanche, Vector3(0.15, 0.85, 0.17), Vector3(0, -0.43, 0), bas, false)
		Geo.boite(hanche, Vector3(0.15, 0.1, 0.26), Vector3(0, -0.85, -0.04), Color(0.12, 0.1, 0.1), false)
		_jambes.append(hanche)
	Geo.boite(self, Vector3(0.42, 0.6, 0.24), Vector3(0, 1.22, 0), haut, false)
	for cote in [-0.27, 0.27]:
		var epaule := Node3D.new()
		epaule.position = Vector3(cote, 1.48, 0)
		add_child(epaule)
		Geo.boite(epaule, Vector3(0.11, 0.58, 0.12), Vector3(0, -0.28, 0), haut, false)
		Geo.boite(epaule, Vector3(0.09, 0.1, 0.1), Vector3(0, -0.6, 0), peau, false)
		_bras.append(epaule)
	Geo.boite(self, Vector3(0.1, 0.1, 0.1), Vector3(0, 1.56, 0), peau, false)
	Geo.sphere(self, 0.13, Vector3(0, 1.72, 0), peau)
	Geo.sphere(self, 0.135, Vector3(0, 1.77, 0.02), CHEVEUX[rng.randi() % CHEVEUX.size()])
	if rng.randf() < 0.3:
		# Sac à dos ou sac de courses
		Geo.boite(self, Vector3(0.3, 0.4, 0.14), Vector3(0, 1.2, 0.19), Color(0.25, 0.25, 0.3), false)
	_pause = rng.randf_range(0.0, 3.0)
	position = depart.lerp(arrivee, rng.randf())


func _process(delta: float) -> void:
	var cible: Vector3 = arrivee if _vers_arrivee else depart
	var bloque := _pause > 0.0
	if monde != null:
		for e in monde.engins:
			if e.global_position.distance_to(global_position) < 7.0:
				bloque = true
	if _pause > 0.0:
		_pause -= delta
	if bloque:
		_animer(0.0, delta)
		return
	var d := cible - position
	d.y = 0.0
	if d.length() < 0.3:
		_vers_arrivee = not _vers_arrivee
		_pause = randf_range(1.0, 6.0)
		return
	var dir := d.normalized()
	position += dir * vitesse * delta
	rotation.y = atan2(-dir.x, -dir.z)
	_animer(vitesse, delta)


func _animer(v: float, delta: float) -> void:
	if v > 0.0:
		_pas += delta * v * 4.5
	else:
		_pas = move_toward(_pas, 0.0, delta * 3.0)
	var a := sin(_pas) * 0.5 if v > 0.0 else 0.0
	_jambes[0].rotation.x = a
	_jambes[1].rotation.x = -a
	_bras[0].rotation.x = -a * 0.8
	_bras[1].rotation.x = a * 0.8
