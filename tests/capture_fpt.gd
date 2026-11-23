## Captures du FPT (rideaux et portes ouverts, cabine) pour vérifier le modèle (outil de développement).
##   godot --path . res://tests/capture_fpt.tscn -- <dossier_de_sortie>
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
	var v = main.fpt
	v.garer(Vector3(-120, 0, -4), PI * 0.5)
	var cam := Camera3D.new()
	cam.near = 0.03
	cam.fov = 70.0
	add_child(cam)
	cam.make_current()
	await _vue(cam, v, Vector3(4.5, 1.7, -8.5), Vector3(0, 1.6, -1.0), "f1_trois_quarts_avant")
	await _vue(cam, v, Vector3(0.0, 1.7, -9.0), Vector3(0, 1.7, 0), "f2_face")
	await _vue(cam, v, Vector3(-8.5, 2.2, 1.0), Vector3(0, 1.8, 0.5), "f3_cote_gauche")
	await _vue(cam, v, Vector3(4.0, 2.0, 10.0), Vector3(0, 1.6, 2.5), "f4_arriere")
	for nom in v.portes:
		v.ouvrir_porte(nom)
	await _attendre(1.6)
	await _vue(cam, v, Vector3(7.5, 2.0, -3.5), Vector3(0, 1.8, 0.5), "f5_tout_ouvert")
	await _vue(cam, v, Vector3(3.0, 1.9, 1.4), Vector3(0.6, 1.9, 1.4), "f6_coffres_droits")
	await _vue(cam, v, Vector3(-3.0, 1.9, 0.6), Vector3(-0.6, 1.9, 1.8), "f7_coffres_gauches")
	await _vue(cam, v, Vector3(0.6, 2.0, 7.5), Vector3(0, 1.8, 3.0), "f8_pompe_devidoirs")
	await _vue(cam, v, Vector3(3.2, 2.2, -2.6), Vector3(0, 2.0, -2.2), "f9_cabine")
	v.camera_cabine.make_current()
	await _attendre(0.4)
	await _photo("f10_place_chef")
	v.camera_cellule.make_current()
	await _attendre(0.4)
	await _photo("f11_equipage")
	await _vue(cam, v, Vector3(-6.0, 8.0, -6.0), Vector3(0, 2.5, 0.5), "f12_toit")
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
