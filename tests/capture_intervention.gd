## Captures d'écran d'une intervention guidée complète (malaise à domicile) :
##   godot --path . res://tests/capture_intervention.tscn -- <dossier_de_sortie>
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
	main.force_scenario = "malaise_domicile"
	main.prochain_appel = 0.0
	await _attendre(0.5)
	main.joueur.teleporter(Vector3(-262, 0.2, -52), 0.0)
	_regarder(Carte().VESTIAIRE + Vector3(0, 1.5, -5))
	await _attendre(0.8)
	await _photo("i1_alerte")
	main._vestiaire()
	main._monter_depart()
	main.vitesse_test = 6.0
	while main.etat != "sur_place":
		await get_tree().process_frame
	main.vitesse_test = 1.0
	await _attendre(1.0)
	var e = main.vsav
	main.joueur.teleporter(e.global_position + e.droite() * 4.5 + e.avant() * 3.0, 0.0)
	_regarder(main._pos_sac())
	await _attendre(0.8)
	await _photo("i2_sur_place")
	main._prendre_sac()
	main.joueur.teleporter(Vector3(255.5, 0.2, -90.6), 0.0)
	_regarder(main.temoin.global_position + Vector3(0, 1.5, 0))
	await _attendre(0.6)
	main._ecouter_temoin()
	await _attendre(0.4)
	await _photo("i3_temoin")
	var v = main.victime
	main.joueur.teleporter(v.global_position + Vector3(-2.2, 0.2, 1.6), 0.0)
	_regarder(v.global_position)
	main._geste(1)
	main._geste(3)
	await _attendre(0.6)
	await _photo("i4_victime")
	main._geste(6)
	main._geste(7)
	main.joueur.teleporter(e.global_position - e.avant() * (e.longueur * 0.5 + 6.0) + e.droite() * 2.5, 0.0)
	_regarder(main._pos_arriere(e))
	await _attendre(1.2)
	await _photo("i5_charger")
	main._partir_hopital()
	main.vitesse_test = 6.0
	while main.etat != "hopital":
		await get_tree().process_frame
	main.vitesse_test = 1.0
	await _attendre(0.8)
	main.joueur.teleporter(main.brancard.global_position - e.avant() * 3.5 + e.droite() * 3.0, 0.0)
	_regarder(main.brancard.global_position + Vector3(0, 0.5, 0))
	await _attendre(0.6)
	await _photo("i6_urgences")
	main._transmettre_iao()
	main._remonter_hopital()
	main.vitesse_test = 6.0
	while main.etat != "reconditionnement":
		await get_tree().process_frame
	main.vitesse_test = 1.0
	await _attendre(0.8)
	main.joueur.teleporter(e.global_position + Vector3(4.5, 0.2, 5.0), 0.0)
	_regarder(e.global_position + Vector3(0, 1.2, 0))
	await _attendre(0.6)
	await _photo("i7_reconditionnement")
	main._reconditionner()
	await _attendre(0.8)
	await _photo("i8_compte_rendu")
	get_tree().quit()


func Carte():
	return load("res://scripts/carte.gd")


func _regarder(cible: Vector3) -> void:
	var j = main.joueur
	var d: Vector3 = cible - (j.global_position + Vector3(0, 1.65, 0))
	j.rotation.y = atan2(-d.x, -d.z)
	j.camera.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())
	j._tangage = j.camera.rotation.x


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _photo(nom: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dossier + "/" + nom + ".png")
	print("capture ", nom)
