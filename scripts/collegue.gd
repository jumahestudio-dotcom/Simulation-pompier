## Un collègue sapeur-pompier géré par l'IA (corps articulé en tenue F1 ou tenue de feu, voir corps.gd).
## Il a un grade, un rôle, un trait de caractère, de la fatigue, du stress,
## et un avis sur le joueur (confiance).
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")
const Corps = preload("res://scripts/corps.gd")

var nom := ""
var grade := ""
var role := ""
var trait_caractere := "pedagogue"   # pedagogue, rouspeteur, prudent, impulsif
var confiance := 50.0
var fatigue := 0.0
var stress := 0.0
var vitesse := 2.6

var _cible := Vector3.ZERO
var _en_mouvement := false
var _chemin: PackedVector3Array = PackedVector3Array()   # points de passage (contournent les murs)
var _t_chemin := 0.0
var _suivi: Node3D = null
var _etiquette: Label3D
var corps: Node3D
var _casque_on := false
var _ari_on := false


func construire(p_nom: String, p_grade: String, p_role: String, tenue_feu: bool) -> void:
	nom = p_nom
	grade = p_grade
	role = p_role
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p_nom)
	corps = Corps.new()
	add_child(corps)
	corps.construire(Corps.tenue_pompier(rng, "feu" if tenue_feu else "f1"))
	corps.equiper(tenue_feu, false)
	_etiquette = Geo.texte(self, "%s %s\n%s" % [grade, nom, role], Vector3(0, 2.3, 0), 28, Color(1, 1, 0.8))


func nom_complet() -> String:
	return "%s %s" % [grade, nom]


func set_casque(v: bool) -> void:
	_casque_on = v
	corps.equiper(_casque_on, _ari_on)


## Appareil respiratoire capelé (bouteille sur le dos, masque sur le visage).
func set_ari(v: bool) -> void:
	_ari_on = v
	corps.equiper(_casque_on, _ari_on)


func aller(pos: Vector3) -> void:
	_suivi = null
	_cible = pos
	_en_mouvement = true
	_calculer_chemin(pos)


## Chemin à pied qui passe par les portes, calculé sur le maillage de navigation.
## Hors des zones navigables (ou si le maillage n'est pas prêt), on va tout droit.
func _calculer_chemin(but: Vector3) -> void:
	_chemin = PackedVector3Array()
	if not is_inside_tree():
		return
	var carte: RID = get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(carte) == 0:
		return
	var depart: Vector3 = global_position
	var proche_d: Vector3 = NavigationServer3D.map_get_closest_point(carte, depart)
	var proche_b: Vector3 = NavigationServer3D.map_get_closest_point(carte, but)
	if proche_d.distance_to(depart) > 2.5 or proche_b.distance_to(but) > 4.0:
		return
	var c: PackedVector3Array = NavigationServer3D.map_get_path(carte, depart, but, true)
	if c.size() >= 2:
		_chemin = c
		_chemin.remove_at(0)
		# Dernier pas jusqu'au but seulement s'il est tout près (sinon il y a un mur entre les deux).
		if _chemin[_chemin.size() - 1].distance_to(but) < 1.2:
			_chemin.append(but)
	else:
		_chemin = PackedVector3Array([but])


func suivre(cible: Node3D) -> void:
	_suivi = cible


func arreter() -> void:
	_suivi = null
	_en_mouvement = false


func teleporter(pos: Vector3) -> void:
	global_position = pos
	_en_mouvement = false
	_chemin = PackedVector3Array()


func _process(delta: float) -> void:
	if not visible:
		return
	var but := _cible
	var actif := _en_mouvement
	if _suivi != null and is_instance_valid(_suivi):
		var derriere: Vector3 = _suivi.global_position + _suivi.global_transform.basis.z * 1.6
		if global_position.distance_to(derriere) > 1.2:
			# On recalcule le chemin vers le joueur de temps en temps.
			_t_chemin -= delta
			if _t_chemin <= 0.0:
				_t_chemin = 0.6
				_calculer_chemin(derriere)
			but = derriere
			actif = true
		else:
			actif = false
			_chemin = PackedVector3Array()
	if actif and _chemin.size() > 0:
		but = _chemin[0]
		var reste: Vector3 = but - global_position
		reste.y = 0.0
		if reste.length() < 0.35 and _chemin.size() > 1:
			_chemin.remove_at(0)
			but = _chemin[0]
	if actif:
		var vers: Vector3 = but - global_position
		vers.y = 0.0
		var d: float = vers.length()
		if d < 0.2:
			if _chemin.size() <= 1:
				_en_mouvement = false
				_chemin = PackedVector3Array()
		else:
			var pas: float = minf(d, vitesse * delta * (1.0 - fatigue * 0.004))
			global_position += vers.normalized() * pas
			rotation.y = atan2(-vers.x, -vers.z)
	# Animation : marche (vitesse réelle) ou respiration au repos.
	corps.animer(vitesse if actif else 0.0, delta)
	# La fatigue et le stress redescendent doucement au repos.
	fatigue = maxf(0.0, fatigue - delta * 0.05)
	stress = maxf(0.0, stress - delta * 0.1)
