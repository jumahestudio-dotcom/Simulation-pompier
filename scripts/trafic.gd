## Une voiture du trafic sur le boulevard. Elle se range et s'arrête
## quand un engin arrive avec les deux-tons.
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const VoitureModele = preload("res://scripts/voiture_modele.gd")
const Modeles = preload("res://scripts/modeles3d.gd")

var sens := 1.0          # +1 vers l'est (ou le sud sur un axe nord-sud), -1 dans l'autre sens
var vitesse := 11.0
var vitesse_croisiere := 11.0
var monde = null    # le script principal, qui connaît les engins
var axe_z := false  # false : route est-ouest ; true : route nord-sud (rocade)
var ligne := 0.0    # coordonnée de l'axe central de la route
var voie := 4.0
var bas_cote := 6.8
var a_min := -390.0
var a_max := 640.0
var ronds_points: Array = []   # positions le long de l'axe des ronds-points à contourner
const RAYON_ANNEAU := 19.0
var _decalage := 0.0
var _a := 0.0       # position le long de la route


func construire(couleur: Color, n: int = 0) -> void:
	# Modèles de Sellier (Polo, T-Cross) en alternance ; voitures dessinées en code s'ils manquent.
	var modeles: Array = Modeles.VOITURES_TRAFIC.keys()
	if Modeles.voiture_trafic(self, modeles[n % modeles.size()], couleur) == null \
			and Modeles.voiture_trafic(self, modeles[(n + 1) % modeles.size()], couleur) == null:
		var types: Array = VoitureModele.TYPES
		VoitureModele.instancier(self, types[absi(hash(couleur) + get_instance_id()) % types.size()], couleur)
	# Carrosserie solide : le joueur ne peut plus traverser la voiture.
	var corps := AnimatableBody3D.new()
	corps.sync_to_physics = false
	var cs := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.85, 1.5, 4.3)
	cs.shape = forme
	cs.position = Vector3(0, 0.75, 0)
	corps.add_child(cs)
	add_child(corps)
	_orienter()


func _orienter() -> void:
	if axe_z:
		rotation.y = PI if sens > 0.0 else 0.0
	else:
		rotation.y = -PI * 0.5 if sens > 0.0 else PI * 0.5


## Position le long de la route, et position latérale (à droite de l'axe).
func _vers_monde(a: float, lateral: float) -> Vector3:
	if axe_z:
		return Vector3(ligne - sens * lateral, 0.0, a)
	return Vector3(a, 0.0, ligne + sens * lateral)


func placer(a: float) -> void:
	_a = a
	vitesse = vitesse_croisiere
	global_position = _vers_monde(_a, voie)
	_orienter()


func _le_long(p: Vector3) -> float:
	return p.z if axe_z else p.x


func _travers(p: Vector3) -> float:
	return p.x if axe_z else p.z


func _process(delta: float) -> void:
	var v_cible := vitesse_croisiere
	var cible_decalage := 0.0
	if monde != null:
		for e in monde.engins:
			var ep: Vector3 = e.global_position
			var ecart: float = _travers(ep) - ligne
			if absf(ecart) > voie + bas_cote:
				continue
			var dx: float = (_le_long(ep) - _a) * sens   # > 0 : l'engin est devant
			if e.sirene and e.en_route and absf(dx) < 45.0:
				# Engin prioritaire proche : on se range et on s'arrête.
				cible_decalage = bas_cote - voie
				v_cible = 0.0
			elif not e.en_route and dx > 0.0 and dx < 14.0 and absf(absf(ecart) - (voie + _decalage)) < 2.0:
				# Engin arrêté devant sur notre voie : on attend.
				v_cible = 0.0
		# Un piéton (le joueur) devant la voiture, sur sa voie : elle freine et s'arrête.
		var j = monde.joueur
		if j != null and j.visible:
			var jp: Vector3 = j.global_position
			var devant: float = (_le_long(jp) - _a) * sens
			if devant > 0.0 and devant < 11.0 and absf(_travers(jp) - _travers(global_position)) < 1.9 and jp.y < 2.0:
				v_cible = 0.0
		for c in monde.voitures:
			if c == self or c.sens != sens or c.axe_z != axe_z or c.ligne != ligne:
				continue
			var d: float = (c._a - _a) * sens
			if d > 0.0 and d < 9.0:
				v_cible = minf(v_cible, c.vitesse * 0.8)
	vitesse = move_toward(vitesse, v_cible, delta * 6.0)
	_decalage = move_toward(_decalage, cible_decalage, delta * 2.0)
	_a += sens * vitesse * delta
	if _a > a_max:
		_a = a_min
	elif _a < a_min:
		_a = a_max
	var lateral := voie + _decalage
	for r in ronds_points:
		var d: float = _a - float(r)
		if absf(d) < RAYON_ANNEAU:
			lateral = maxf(lateral, sqrt(RAYON_ANNEAU * RAYON_ANNEAU - d * d))
	global_position = _vers_monde(_a, lateral)
