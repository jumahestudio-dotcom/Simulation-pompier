extends RefCounted
## Charge le modèle 3D de fourgon déposé par le joueur (modeles/crafter.glb) et le prépare pour le VSAV :
## mis à l'échelle réelle, tourné l'avant vers -z, peint en rouge, logos et texte de marque retirés,
## sièges de minibus et rideaux enlevés, vitres de la cellule occultées.
## Le fichier n'est pas dans le dépôt : s'il manque, le VSAV dessiné en code est utilisé.

const CHEMIN := "res://modeles/crafter.glb"
const ECHELLE := 1.35          # pneus de 0,70 m, largeur 2,04 m, empattement 4,5 m
const DZ := 0.39               # décalage pour garder la cabine et la porte latérale à leur place

## Ce qui disparaît : marque, sièges et équipement du minibus.
const A_CACHER := ["e_logo_chromeShape", "e_signShape", "wheelLogo", "4_Salon_seats", "i_interior_curtains",
	"interiorBase_seat12", "interiorBase_seat18", "i_lights_18_seats", "i_trunk_18_seats", "e_cooler"]
const PORTES := {
	"avant_gauche": "frontLeftDoorAction",
	"avant_droite": "frontRightDoorAction",
	"laterale": "SideRightDoorAction",
	"arriere_gauche": "backLeftDoorAction",
	"arriere_droite": "backRightDoorAction",
}

static var _modele: Node3D = null
static var _essaye := false


static func disponible() -> bool:
	return FileAccess.file_exists(CHEMIN)


## Repère du modèle → repère de l'engin (avant vers -z).
static func vers_engin(p: Vector3) -> Vector3:
	return Vector3(-p.x * ECHELLE, p.y * ECHELLE, -p.z * ECHELLE + DZ)


static func _charger() -> Node3D:
	if _essaye:
		return _modele
	_essaye = true
	if not disponible():
		return null
	var doc := GLTFDocument.new()
	var etat := GLTFState.new()
	if doc.append_from_file(CHEMIN, etat) != OK:
		push_warning("Modèle du VSAV illisible : " + CHEMIN)
		return null
	_modele = doc.generate_scene(etat)
	return _modele


## Ajoute le fourgon à l'engin. Renvoie {"racine", "portes": {nom: noeud}, "pistes": {nom: [[animation, piste]]}}
## ou un dictionnaire vide si le modèle n'est pas là.
static func instancier(e: Node3D, rouge: Material) -> Dictionary:
	var m := _charger()
	if m == null:
		return {}
	var racine := Node3D.new()
	racine.name = "Fourgon"
	racine.rotation.y = PI
	racine.scale = Vector3.ONE * ECHELLE
	racine.position = Vector3(0, 0, DZ)
	e.add_child(racine)
	var copie: Node3D = m.duplicate()
	racine.add_child(copie)
	# Les animations des portes sont lues à la main, image par image : le lecteur ne doit rien jouer.
	var anims: Array = []
	for ap in copie.find_children("*", "AnimationPlayer", true, false):
		var lecteur: AnimationPlayer = ap
		lecteur.stop()
		lecteur.active = false
		for nom in lecteur.get_animation_list():
			anims.append(lecteur.get_animation(nom))
	for n in copie.find_children("*", "", true, false):
		var nm: String = n.name
		for c in A_CACHER:
			if nm.begins_with(c) and n is Node3D:
				(n as Node3D).visible = false
	# Peinture rouge à la place du blanc, vitres de la cellule occultées
	for mi in copie.find_children("*", "MeshInstance3D", true, false):
		var mesh_i: MeshInstance3D = mi
		for s in mesh_i.mesh.get_surface_count():
			var mat := mesh_i.mesh.surface_get_material(s)
			if mat != null and mat.resource_name == "Car_Paint":
				mesh_i.set_surface_override_material(s, rouge)
	var portes := {}
	var pistes := {}
	for cle in PORTES:
		var noeud := _trouver(copie, PORTES[cle])
		if noeud == null:
			continue
		portes[cle] = noeud
		pistes[cle] = []
		for a in anims:
			var an: Animation = a
			if an.resource_name.begins_with("Open all"):
				continue
			for t in an.get_track_count():
				var chemin := an.track_get_path(t)
				if chemin.get_name(chemin.get_name_count() - 1) == noeud.name:
					pistes[cle].append([an, t])
	return {"racine": racine, "portes": portes, "pistes": pistes}


static func _trouver(n: Node, debut: String) -> Node3D:
	for x in n.find_children(debut + "*", "Node3D", true, false):
		return x
	return null


## Boîte englobante des maillages sous "n", exprimée dans le repère de "n".
static func boite_locale(n: Node3D) -> AABB:
	var bb := AABB()
	var premier := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		var t := Transform3D.IDENTITY
		var x: Node = m
		while x != n and x != null:
			t = (x as Node3D).transform * t
			x = x.get_parent()
		var b: AABB = t * m.get_aabb()
		if premier:
			bb = b
			premier = false
		else:
			bb = bb.merge(b)
	return bb


## Place les pistes d'animation d'une porte à l'instant k (0 = fermée, 1 = ouverte).
static func poser_porte(noeud: Node3D, pistes: Array, k: float) -> void:
	for pa in pistes:
		var an: Animation = pa[0]
		var t: int = pa[1]
		var temps: float = k * an.length
		match an.track_get_type(t):
			Animation.TYPE_ROTATION_3D:
				noeud.quaternion = an.rotation_track_interpolate(t, temps)
			Animation.TYPE_POSITION_3D:
				noeud.position = an.position_track_interpolate(t, temps)
			Animation.TYPE_SCALE_3D:
				noeud.scale = an.scale_track_interpolate(t, temps)
