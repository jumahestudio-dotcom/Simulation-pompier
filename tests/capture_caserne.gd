## Captures de la caserne équipée (outil de développement).
##   godot --path . res://tests/capture_caserne.tscn -- <dossier_de_sortie>
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
	var cam := Camera3D.new()
	cam.near = 0.05
	cam.fov = 55.0
	add_child(cam)
	cam.make_current()
	await _attendre(0.5)
	for v in [["k01_remise", Vector3(-250, 2.4, -17), Vector3(-252, 1.0, -50)],
			["k02_tuyaux", Vector3(-223, 1.7, -38), Vector3(-215.5, 1.3, -45)],
			["k03_sport", Vector3(-278.5, 1.8, -34), Vector3(-284, 0.8, -45)],
			["k04_vestiaire", Vector3(-272, 1.7, -56.5), Vector3(-280, 1.0, -67)],
			["k05_ari", Vector3(-261, 1.7, -56.5), Vector3(-266, 1.2, -69)],
			["k06_salle", Vector3(-244, 1.7, -55.5), Vector3(-254, 1.0, -67)],
			["k07_bureau", Vector3(-222, 1.7, -55), Vector3(-229, 1.0, -61.5)],
			["k08_chambres", Vector3(-224, 1.7, -63), Vector3(-226, 0.4, -69.5)],
			["k09_tour", Vector3(-245, 2.5, -77.5), Vector3(-219, 6, -74)],
			["k10_parking", Vector3(-206, 3, -10), Vector3(-212, 0.5, -45)],
			["k11_vl", Vector3(-229, 1.7, -29), Vector3(-222, 0.8, -21)],
			["k12_facade", Vector3(-250, 7, 10), Vector3(-250, 3, -30)]]:
		cam.global_position = v[1]
		cam.look_at(v[2])
		await _attendre(0.4)
		await _photo(v[0])
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
