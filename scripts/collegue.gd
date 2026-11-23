## Un collègue sapeur-pompier géré par l'IA (forme simple : un corps et un casque).
## Il a un grade, un rôle, un trait de caractère, de la fatigue, du stress,
## et un avis sur le joueur (confiance).
extends Node3D

const Geo = preload("res://scripts/geo.gd")

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
var _suivi: Node3D = null
var _etiquette: Label3D
var _casque: MeshInstance3D


func construire(p_nom: String, p_grade: String, p_role: String, tenue_feu: bool) -> void:
	nom = p_nom
	grade = p_grade
	role = p_role
	var corps: MeshInstance3D = Geo.cylindre(self, 0.3, 1.2, Vector3(0, 0.9, 0), Color(0.11, 0.14, 0.28))
	corps.name = "Corps"
	Geo.boite(self, Vector3(0.62, 0.1, 0.3), Vector3(0, 1.1, 0), Color(0.95, 0.85, 0.1), false)  # bande jaune
	Geo.sphere(self, 0.17, Vector3(0, 1.67, 0), Color(0.93, 0.78, 0.65))
	_casque = Geo.sphere(self, 0.2, Vector3(0, 1.78, 0), Color(0.85, 0.85, 0.88))
	_casque.scale = Vector3(1, 0.65, 1.1)
	_casque.visible = tenue_feu
	_etiquette = Geo.texte(self, "%s %s\n%s" % [grade, nom, role], Vector3(0, 2.3, 0), 28, Color(1, 1, 0.8))


func nom_complet() -> String:
	return "%s %s" % [grade, nom]


func set_casque(v: bool) -> void:
	_casque.visible = v


func aller(pos: Vector3) -> void:
	_suivi = null
	_cible = pos
	_en_mouvement = true


func suivre(cible: Node3D) -> void:
	_suivi = cible


func arreter() -> void:
	_suivi = null
	_en_mouvement = false


func teleporter(pos: Vector3) -> void:
	global_position = pos
	_en_mouvement = false


func _process(delta: float) -> void:
	if not visible:
		return
	var but := _cible
	var actif := _en_mouvement
	if _suivi != null and is_instance_valid(_suivi):
		var derriere: Vector3 = _suivi.global_position + _suivi.global_transform.basis.z * 1.6
		if global_position.distance_to(derriere) > 1.2:
			but = derriere
			actif = true
		else:
			actif = false
	if actif:
		var vers: Vector3 = but - global_position
		vers.y = 0.0
		var d: float = vers.length()
		if d < 0.2:
			_en_mouvement = false
		else:
			var pas: float = minf(d, vitesse * delta * (1.0 - fatigue * 0.004))
			global_position += vers.normalized() * pas
			rotation.y = atan2(-vers.x, -vers.z)
	# La fatigue et le stress redescendent doucement au repos.
	fatigue = maxf(0.0, fatigue - delta * 0.05)
	stress = maxf(0.0, stress - delta * 0.1)
