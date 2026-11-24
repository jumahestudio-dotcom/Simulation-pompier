## Un passant : il fait des allers-retours sur un trottoir, s'arrête de temps en temps
## et s'immobilise quand un engin passe tout près.
extends Node3D

const Corps = preload("res://scripts/corps.gd")

var depart := Vector3.ZERO
var arrivee := Vector3.ZERO
var monde = null
var vitesse := 1.3
var _vers_arrivee := true
var _pause := 0.0
var corps: Node3D

func construire(rng: RandomNumberGenerator) -> void:
	var sexe := "F" if rng.randf() < 0.5 else "M"
	var r := rng.randf()
	var age: int = rng.randi_range(16, 35) if r < 0.4 else (rng.randi_range(36, 64) if r < 0.8 else rng.randi_range(65, 88))
	corps = Corps.new()
	add_child(corps)
	corps.construire(Corps.tenue_civile(rng, sexe, age))
	vitesse = rng.randf_range(1.1, 1.6)
	if age > 70:
		vitesse = rng.randf_range(0.7, 1.0)
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
	corps.animer(v, delta)
