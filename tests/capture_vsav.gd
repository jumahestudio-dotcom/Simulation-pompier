## Captures du VSAV (portes ouvertes, cellule) pour vérifier le modèle (outil de développement).
##   godot --path . res://tests/capture_vsav.tscn -- <dossier_de_sortie>
extends Node

var main
var dossier := "user://captures"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dossier = args[0]
	DirAccess.make_dir_recursive_absolute(dossier)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _attendre(1.0)
	var v = main.vsav
	v.garer(Vector3(-120, 0, -4), PI * 0.5)
	var cam := Camera3D.new()
	cam.near = 0.03
	cam.fov = 75.0
	add_child(cam)
	cam.make_current()
	var d: float = v.VsavModele.Z_AR - 2.95
	await _vue(cam, v, Vector3(-5.5, 1.6, -4.0), Vector3(0, 1.3, 0), "v1_ferme_avant")
	await _vue(cam, v, Vector3(-6.5, 1.8, 2.0), Vector3(0, 1.4, 0.5), "v2_cote_gauche")
	await _vue(cam, v, Vector3(3.5, 1.8, 9.0 + d), Vector3(0, 1.3, 2.0), "v0_arriere_ferme")
	for nom in ["arriere_gauche", "arriere_droite", "laterale", "avant_droite"]:
		v.ouvrir_porte(nom)
	await _attendre(1.5)
	await _vue(cam, v, Vector3(5.0, 1.7, -4.5), Vector3(0, 1.3, 0), "v3_portes_ouvertes")
	await _vue(cam, v, Vector3(0.0, 1.75, 7.5 + d), Vector3(0, 1.3, 1.0 + d), "v4_arriere")
	await _vue(cam, v, Vector3(0.0, 1.75, 3.9 + d), Vector3(0, 1.35, -0.6), "v5_cellule")
	await _vue(cam, v, Vector3(-0.55, 1.95, 2.7 + d), Vector3(0.95, 1.3, 1.6 + d), "v6_sieges")
	await _vue(cam, v, Vector3(0.25, 2.0, 2.3 + d * 0.5), Vector3(0.1, 1.5, -0.9), "v7_cloison")
	await _vue(cam, v, Vector3(2.2, 1.7, 0.2), Vector3(-0.5, 1.3, 0.8), "v8_porte_laterale")
	await _vue(cam, v, Vector3(4.5, 1.4, -6.5), Vector3(0, 1.3, -1.0), "v10_trois_quarts_avant")
	v.camera_cabine.make_current()
	await _attendre(0.4)
	await _photo("v9_cabine")
	get_tree().quit()


func _vue(cam: Camera3D, v, pos_l: Vector3, cible_l: Vector3, nom: String) -> void:
	cam.make_current()
	cam.global_position = v.to_global(pos_l)
	cam.look_at(v.to_global(cible_l))
	await _attendre(0.4)
	await _photo(nom)


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _photo(nom: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dossier + "/" + nom + ".png")
	print("capture ", nom)
