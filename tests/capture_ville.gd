## Captures de la ville, sans interface (outil de développement).
##   godot --path . res://tests/capture_ville.tscn -- <dossier>
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
	for v in [["v1_centre_aerien", Vector3(-120, 45, 60), Vector3(-20, 0, -40)],
			["v2_rue_commercante", Vector3(-165, 1.8, -4), Vector3(-125, 3.5, -16)],
			["v3_carrefour", Vector3(-46, 2.2, 30), Vector3(-50, 2.5, -8)],
			["v4_toits", Vector3(80, 22, -25), Vector3(130, 8, -60)],
			["v5_grands_ensembles", Vector3(-120, 70, -150), Vector3(-200, 0, -320)],
			["v6_lotissement", Vector3(55, 1.8, -224), Vector3(90, 2.0, -230)],
			["v7_zone_activites", Vector3(380, 70, 120), Vector3(520, 0, -40)],
			["v8_vue_ensemble", Vector3(120, 330, 620), Vector3(80, 0, -60)],
			["v9_rue_laterale", Vector3(-55, 1.8, 60), Vector3(-55, 3, 100)],
			["v10_square", Vector3(-30, 5, 370), Vector3(-70, 0, 330)],
			["v11_placette", Vector3(-296, 1.8, -36), Vector3(-312, 1.2, -70)],
			["v12_jardins", Vector3(60, 9, -200), Vector3(85, 0, -232)],
			["v13_coeur_ilot", Vector3(-150, 14, -60), Vector3(-120, 0, -90)]]:
		if args.size() > 1 and not args[1].split(",").has(String(v[0]).get_slice("_", 0)):
			continue
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
