## Captures des modèles 3D personnels (voitures, mobilier, végétation), sans interface.
##   godot --path . res://tests/capture_modeles.tscn -- <dossier>
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
	await _attendre(1.5)
	if "hud" in main and main.hud is CanvasLayer:
		main.hud.visible = false
	var cam := Camera3D.new()
	cam.far = 3000.0
	add_child(cam)
	cam.make_current()
	for v in [["m1_vl_chef", Vector3(-226.5, 1.8, -15.5), Vector3(-222, 0.8, -21.5)],
			["m2_parking_personnel", Vector3(-206.5, 2.5, -55.0), Vector3(-211.6, 0.6, -45.0)],
			["m3_poteau_caserne", Vector3(-294.5, 1.4, -8.5), Vector3(-292, 0.5, -11.0)],
			["m4_boulevard_mobilier", Vector3(-60, 1.7, -9.0), Vector3(-20, 0.8, -12.5)],
			["m7_banc", Vector3(-100, 1.6, -9.5), Vector3(-92, 0.5, -12.5)],
			["m8_cour", Vector3(-230, 1.8, -76), Vector3(-226, 0.4, -80)],
			["m5_square", Vector3(-60, 6, 270), Vector3(-75, 0, 320)],
			["m6_ferme", Vector3(-585, 5, -150), Vector3(-610, 3, -120)]]:
		cam.global_position = v[1]
		cam.look_at(v[2])
		await _attendre(0.6)
		await _photo(v[0])
	get_tree().quit()


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _photo(nom: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dossier + "/" + nom + ".png")
	print("capture ", nom)
