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
			["v13_coeur_ilot", Vector3(-150, 14, -60), Vector3(-120, 0, -90)],
			["v14_rocade", Vector3(-406, 3.0, 62), Vector3(-420, 1.0, 0)],
			["v15_cher", Vector3(-150, 3.0, 154), Vector3(-90, 0, 168)],
			["v16_parking", Vector3(-140, 6, -158), Vector3(-125, 0, -182)],
			["v17_facades", Vector3(-110, 1.8, -2), Vector3(-80, 6, -14)],
			["v18_trafic", Vector3(-150, 1.6, -3.5), Vector3(-120, 0.8, 3)],
			["v19_trafic_rocade", Vector3(-411, 1.8, -150), Vector3(-420, 0.8, -100)],
			["v20_kiosque", Vector3(-38, 2.0, 306), Vector3(-46, 1.3, 296)],
			["v21_square_erables", Vector3(-10, 4, 330), Vector3(-40, 3, 285)],
			["v22_tilleuls_bosquet", Vector3(-100, 4, -240), Vector3(-128, 3, -222)],
			["v23_coffret", Vector3(-186, 1.7, -244), Vector3(-192.5, 0.8, -250)],
			["v24_chantier", Vector3(519, 6, -6), Vector3(519, 0.5, 21)],
			["v25_entrepot", Vector3(390, 4, 60), Vector3(371.5, 2, 83)],
			["v26_vtu", Vector3(-232, 2.2, -70), Vector3(-240, 1, -75.5)],
			["v27_remise_sacs", Vector3(-266, 1.7, -42), Vector3(-268.3, 0.4, -45)],
			["v28_remise_tuyaux", Vector3(-219, 1.6, -31.5), Vector3(-215.8, 0.4, -29.5)]]:
		if args.size() > 1 and not args[1].split(",").has(String(v[0]).get_slice("_", 0)):
			continue
		cam.global_position = v[1]
		cam.look_at(v[2])
		if String(v[0]).begins_with("v18") or String(v[0]).begins_with("v19"):
			# Vue sur une voiture du trafic, arrêtée le temps de la photo
			for c in main.voitures:
				c.set_process(false)
			var auto: Node3D = main.voitures[2 if String(v[0]).begins_with("v18") else 13]
			var av := -auto.global_basis.z
			cam.global_position = auto.global_position + av * 6.0 + auto.global_basis.x * 3.5 + Vector3(0, 1.6, 0)
			cam.look_at(auto.global_position + Vector3(0, 0.7, 0))
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
