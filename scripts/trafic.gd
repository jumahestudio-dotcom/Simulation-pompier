## Une voiture du trafic sur le boulevard. Elle se range et s'arrête
## quand un engin arrive avec les deux-tons.
extends Node3D

const Geo = preload("res://scripts/geo.gd")

var sens := 1.0          # +1 vers l'est, -1 vers l'ouest
var vitesse := 11.0
var monde = null    # le script principal, qui connaît les engins
var _decalage := 0.0
const VOIE := 4.0
const BAS_COTE := 6.8
const X_MIN := -315.0
const X_MAX := 315.0


func construire(couleur: Color) -> void:
	Geo.boite(self, Vector3(1.8, 0.8, 4.2), Vector3(0, 0.6, 0), couleur, false)
	Geo.boite(self, Vector3(1.6, 0.6, 2.2), Vector3(0, 1.3, 0.2), couleur.darkened(0.2), false)
	Geo.boite(self, Vector3(1.5, 0.45, 0.05), Vector3(0, 1.3, -0.92), Color(0.2, 0.3, 0.4), false)
	for zz in [-1.3, 1.3]:
		for xx in [-0.9, 0.9]:
			var r: MeshInstance3D = Geo.cylindre(self, 0.33, 0.25, Vector3(xx, 0.33, zz), Color(0.05, 0.05, 0.05))
			r.rotation.z = PI * 0.5
	rotation.y = -PI * 0.5 if sens > 0.0 else PI * 0.5


func _process(delta: float) -> void:
	var v_cible := 11.0
	var cible_decalage := 0.0
	var x: float = global_position.x
	if monde != null:
		for e in monde.engins:
			var ep: Vector3 = e.global_position
			if absf(ep.z) > 12.0:
				continue
			var dx: float = (ep.x - x) * sens   # > 0 : l'engin est devant
			if e.sirene and e.en_route and absf(dx) < 45.0:
				# Engin prioritaire proche : on se range et on s'arrête.
				cible_decalage = BAS_COTE - VOIE
				v_cible = 0.0
			elif not e.en_route and dx > 0.0 and dx < 14.0 and absf(absf(ep.z) - (VOIE + _decalage)) < 2.0:
				# Engin arrêté devant sur notre voie : on attend.
				v_cible = 0.0
		for c in monde.voitures:
			if c == self:
				continue
			if c.sens != sens:
				continue
			var d: float = (c.global_position.x - x) * sens
			if d > 0.0 and d < 9.0:
				v_cible = minf(v_cible, c.vitesse * 0.8)
	vitesse = move_toward(vitesse, v_cible, delta * 6.0)
	_decalage = move_toward(_decalage, cible_decalage, delta * 2.0)
	x += sens * vitesse * delta
	if x > X_MAX:
		x = X_MIN
	elif x < X_MIN:
		x = X_MAX
	global_position = Vector3(x, 0.0, sens * (VOIE + _decalage))
