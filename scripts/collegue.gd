## Un collègue sapeur-pompier géré par l'IA (forme simple : un corps et un casque).
## Il a un grade, un rôle, un trait de caractère, de la fatigue, du stress,
## et un avis sur le joueur (confiance).
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Tex = preload("res://scripts/textures.gd")

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
var _jambes: Array = []
var _bras: Array = []
var _pas := 0.0


func construire(p_nom: String, p_grade: String, p_role: String, tenue_feu: bool) -> void:
	nom = p_nom
	grade = p_grade
	role = p_role
	var marine := Color(0.10, 0.13, 0.25)
	var tenue := Color(0.16, 0.17, 0.2) if tenue_feu else marine
	var peau: Color = [Color(0.93, 0.78, 0.65), Color(0.78, 0.6, 0.45), Color(0.5, 0.35, 0.25)].pick_random()
	var bande := Color(0.95, 0.85, 0.15)
	# Jambes (avec pivot à la hanche pour la marche)
	for cote in [-1.0, 1.0]:
		var hanche := Node3D.new()
		hanche.position = Vector3(cote * 0.13, 0.95, 0)
		add_child(hanche)
		var jambe: MeshInstance3D = _capsule(hanche, 0.11, 0.95, Vector3(0, -0.47, 0), tenue)
		jambe.name = "jambe"
		Geo.boite(hanche, Vector3(0.23, 0.05, 0.23), Vector3(0, -0.5, 0), bande, false)
		Geo.boite(hanche, Vector3(0.2, 0.14, 0.32), Vector3(0, -0.88, -0.05), Color(0.05, 0.05, 0.05), false)
		_jambes.append(hanche)
	# Torse
	var torse: Node3D = Geo.boite(self, Vector3(0.46, 0.62, 0.28), Vector3(0, 1.28, 0), tenue, false)
	torse.name = "Corps"
	Geo.boite(self, Vector3(0.48, 0.06, 0.3), Vector3(0, 1.18, 0), bande, false)
	Geo.boite(self, Vector3(0.48, 0.06, 0.3), Vector3(0, 1.42, 0), Color(0.85, 0.85, 0.85), false)
	if not tenue_feu:
		var dos: Label3D = Geo.texte(self, "POMPIERS", Vector3(0, 1.3, 0.15), 14, Color.WHITE, false)
		dos.outline_size = 0
	# Bras
	for cote in [-1.0, 1.0]:
		var epaule := Node3D.new()
		epaule.position = Vector3(cote * 0.3, 1.52, 0)
		add_child(epaule)
		_capsule(epaule, 0.08, 0.62, Vector3(0, -0.3, 0), tenue)
		Geo.sphere(epaule, 0.07, Vector3(0, -0.64, 0), Color(0.1, 0.1, 0.1) if tenue_feu else peau)
		_bras.append(epaule)
	# Tête, casque
	Geo.cylindre(self, 0.07, 0.1, Vector3(0, 1.63, 0), peau)
	Geo.sphere(self, 0.14, Vector3(0, 1.78, 0), peau)
	_casque = Geo.sphere(self, 0.17, Vector3(0, 1.86, 0.01), Color(0.85, 0.86, 0.9))
	_casque.scale = Vector3(1.0, 0.85, 1.12)
	_casque.material_override = Tex.carrosserie(Color(0.82, 0.84, 0.88))
	_casque.visible = tenue_feu
	_etiquette = Geo.texte(self, "%s %s\n%s" % [grade, nom, role], Vector3(0, 2.3, 0), 28, Color(1, 1, 0.8))


func _capsule(parent: Node, rayon: float, hauteur: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = rayon
	cm.height = hauteur
	mi.mesh = cm
	mi.material_override = Geo.mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


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
	# Animation de marche : on balance les jambes et les bras.
	if actif:
		_pas += delta * 9.0
	else:
		_pas = move_toward(_pas, round(_pas / PI) * PI, delta * 6.0)
	var a: float = sin(_pas) * 0.55
	if _jambes.size() == 2:
		_jambes[0].rotation.x = a
		_jambes[1].rotation.x = -a
		_bras[0].rotation.x = -a * 0.8
		_bras[1].rotation.x = a * 0.8
	# La fatigue et le stress redescendent doucement au repos.
	fatigue = maxf(0.0, fatigue - delta * 0.05)
	stress = maxf(0.0, stress - delta * 0.1)
