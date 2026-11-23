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
	main.joueur.teleporter(Vector3(-250, 0.2, 10), PI * 0.15)
	await _attendre(0.5)
	await _photo("2_boulevard")
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
