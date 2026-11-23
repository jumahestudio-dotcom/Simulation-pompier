## Prend quelques captures d'écran pour vérifier le rendu (outil de développement).
##   godot --path . res://tests/capture.tscn -- <dossier_de_sortie>
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
	await _photo("1_caserne")
	main.joueur.teleporter(Vector3(-250, 0.2, -22), PI * 0.5 - 0.45)
	main.joueur.camera.rotation.x = -0.12
	await _attendre(0.5)
	await _photo("1b_remise")
	main.joueur.camera.rotation.x = 0.0
	main.joueur.teleporter(Vector3(-250, 0.2, 10), PI * 0.15)
	await _attendre(0.5)
	await _photo("2_boulevard")
	# Vues aériennes des quartiers
	var cam := Camera3D.new()
	cam.far = 3000.0
	add_child(cam)
	cam.make_current()
	var vues := [
		["7_vue_ensemble", Vector3(120, 330, 620), Vector3(80, 0, -60)],
		["8_centre_ancien", Vector3(-120, 45, 60), Vector3(-20, 0, -40)],
		["9_grands_ensembles", Vector3(-120, 70, -150), Vector3(-200, 0, -320)],
		["10_pavillons", Vector3(150, 40, -130), Vector3(220, 0, -260)],
		["11_zone_activites", Vector3(380, 70, 120), Vector3(520, 0, -40)],
		["12_rocade", Vector3(-370, 40, -60), Vector3(-420, 0, -220)],
		["13_bords_du_cher", Vector3(40, 30, 130), Vector3(150, 0, 230)],
		["14_rue_commercante", Vector3(-165, 1.8, -4), Vector3(-125, 3.5, -16)],
		["15_carrefour", Vector3(-46, 2.2, 30), Vector3(-50, 2.5, -8)],
		["16_lotissement", Vector3(55, 1.8, -224), Vector3(90, 2.0, -230)],
		["17_tour", Vector3(-205, 6, -228), Vector3(-235, 14, -255)],
		["18_toits", Vector3(80, 22, -25), Vector3(130, 8, -60)],
	]
	for v in vues:
		cam.global_position = v[1]
		cam.look_at(v[2])
		await _attendre(0.6)
		await _photo(v[0])
	cam.queue_free()
	main.joueur.camera.make_current()
	await _attendre(0.2)
	main.force_scenario = "feu_appartement"
	main.prochain_appel = 0.0
	await _attendre(0.3)
	await _photo("3_ticket")
	main._vestiaire()
	main._monter_depart()
	main.vitesse_test = 6.0
	await _attendre(3.0)
	await _photo("4_trajet")
	while main.etat != "sur_place":
		await get_tree().process_frame
	main.vitesse_test = 1.0
	await _attendre(1.0)
	main.joueur.teleporter(Vector3(-60, 0.2, -85), -PI * 0.5 + 0.3)
	main.joueur.camera.rotation.x = 0.25
	await _attendre(1.0)
	await _photo("5_immeuble")
	main._capeler()
	main._prendre_lance()
	main._monter_escalier()
	main.joueur.teleporter(Vector3(-32, 6.3, -103), PI)
	main.joueur.camera.rotation.x = 0.0
	main.test_arrosage = true
	await _attendre(1.5)
	await _photo("6_feu_interieur")
	get_tree().quit()


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _photo(nom: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dossier + "/" + nom + ".png")
	print("capture ", nom)
