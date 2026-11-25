extends RefCounted
## Modèles SDIS37 de Sellier (dossier modeles/sdis37/, versionné avec le jeu).
## Ces fichiers sont « z vers le haut » (export trimesh) : on les redresse pour Godot
## (y vers le haut) et l'on donne aux pièces sans matériau la couleur de leurs sommets.

const DOSSIER := "res://modeles/sdis37/"
const TENUES := {
	"ceremonie": "Femme_Ceremonie_SDIS37_V2.glb",
	"sport": "Femme_Sport_SDIS37_V2.glb",
	"station": "Femme_Station_SDIS37_V2.glb",
	"secours_routier": "Femme_Secours_routier_SDIS37_V2.glb",
	"incendie": "Femme_Incendie_SDIS37_V2.glb",
}
const MASQUE := "Masque_ARI_SDIS37.glb"
const ARI := "ARI_Bouteille_Dosseret_SDIS37.glb"
const CASQUE := "Casque_F1_complet_SDIS37.glb"
const CAGOULE := "Cagoule_F1_SDIS37.glb"
const GILET := "Gilet_Haute_Visibilite_SDIS37.glb"
const GANTS := "Gants_intervention_SDIS37.glb"
const BOTTES := "Bottes_intervention_SDIS37.glb"
const CASERNE := "Caserne_SDIS37_V2_Godot.glb"
const MASTER := "VSAV_RenaultMaster_V4.glb"

static var _cache := {}
static var _mat_sommets: StandardMaterial3D
static var _mat_vitre: StandardMaterial3D


static func present(nom: String) -> bool:
	return FileAccess.file_exists(DOSSIER + nom)


## Copie redressée du modèle (pied à y = 0, avant vers -z), ou null si le fichier manque.
static func instance(nom: String) -> Node3D:
	if not _cache.has(nom):
		var n: Node3D = null
		if present(nom):
			var doc := GLTFDocument.new()
			var etat := GLTFState.new()
			if doc.append_from_file(DOSSIER + nom, etat) == OK:
				var brut := doc.generate_scene(etat)
				n = Node3D.new()
				n.name = nom.get_basename()
				brut.rotation.x = -PI / 2.0   # z (haut dans le fichier) -> y ; -y (avant) -> +z
				n.add_child(brut)
				_preparer(brut)
		_cache[nom] = n
	var o: Node3D = _cache[nom]
	return null if o == null else o.duplicate()


static func _preparer(racine: Node) -> void:
	if _mat_sommets == null:
		_mat_sommets = StandardMaterial3D.new()
		_mat_sommets.vertex_color_use_as_albedo = true
		_mat_sommets.vertex_color_is_srgb = true
		_mat_sommets.roughness = 0.8
		_mat_vitre = _mat_sommets.duplicate()
		_mat_vitre.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_vitre.roughness = 0.1
		_mat_vitre.metallic = 0.3
	for mi in racine.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in m.mesh.get_surface_count():
			var a := m.mesh.surface_get_arrays(s)
			var c = a[Mesh.ARRAY_COLOR]
			if c != null and (c as PackedColorArray).size() > 0:
				# Vitres : couleur des sommets un peu transparente
				m.set_surface_override_material(s, _mat_vitre if (c as PackedColorArray)[0].a < 0.95 else _mat_sommets)


## Pièce du modèle par début de nom (ex. "09_Tete"), ou null.
static func piece(racine: Node, debut: String) -> MeshInstance3D:
	for mi in racine.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with(debut):
			return mi
	return null
