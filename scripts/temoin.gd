## Un civil sur les lieux : la personne qui a appelé (fille, voisine, passant…)
## ou l'infirmière d'accueil des urgences. Debout, il se tourne vers le joueur
## et donne des renseignements quand on lui parle (touche E).
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Corps = preload("res://scripts/corps.gd")

var role := "Témoin"
var corps: Node3D
var _etiquette: Label3D
var _regarde: Node3D = null


func construire(p_role: String, sexe: String, age: int, graine: int, blouse: bool = false) -> void:
	role = p_role
	var rng := RandomNumberGenerator.new()
	rng.seed = graine
	corps = Corps.new()
	add_child(corps)
	var tenue: Dictionary = Corps.tenue_civile(rng, sexe, age)
	if blouse:
		# Tenue de soignant : haut et pantalon bleu-vert
		tenue["haut"] = Color(0.45, 0.68, 0.7)
		tenue["bas"] = Color(0.42, 0.64, 0.66)
		tenue["chaussures"] = Color(0.92, 0.92, 0.92)
		tenue["veste"] = false
		tenue["sac"] = false
		tenue["jupe"] = false
		tenue["manches_longues"] = false
	corps.construire(tenue)
	_etiquette = Geo.texte(self, role, Vector3(0, 2.15, 0), 28, Color(0.75, 0.9, 1.0))


## Le civil se tourne vers ce nœud (le joueur, en général).
func regarder(n: Node3D) -> void:
	_regarde = n


func _process(delta: float) -> void:
	if not visible:
		return
	if _regarde != null and is_instance_valid(_regarde) and _regarde.visible:
		var v: Vector3 = _regarde.global_position - global_position
		v.y = 0.0
		if v.length() < 8.0 and v.length() > 0.3:
			var voulu := atan2(-v.x, -v.z)
			rotation.y = lerp_angle(rotation.y, voulu, minf(1.0, delta * 3.0))
	corps.animer(0.0, delta)
