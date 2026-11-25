## Captures des pompiers 3D (modèle de Sellier) dans le jeu (outil de développement).
##   godot --path . res://tests/capture_pompiers3d.tscn -- <dossier_de_sortie>
extends Node

var main
var dossier := "user://captures"
var cam: Camera3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dossier = args[0]
	DirAccess.make_dir_recursive_absolute(dossier)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if main.hud is CanvasLayer:
		main.hud.visible = false
	await _attendre(1.0)
	cam = Camera3D.new()
	cam.near = 0.03
	cam.fov = 50.0
	add_child(cam)
	cam.make_current()
	# 1. Équipage VSAV dans la remise (tête nue), et le sapeur au standard
	var vs: Array = main.equipages["VSAV"]
	var l = vs[0]
	await _vue(l.global_position + Vector3(1.2, 1.65, -2.4), l.global_position + Vector3(0.6, 1.2, 0), "q1_equipage_vsav")
	await _vue(Vector3(-222.5, 1.6, -57.2), Vector3(-226.6, 1.1, -60.6), "q2_standard")
	# Sapeur en tenue de sport dans la salle de sport
	for c in main.get_children():
		if c.get("nom") == "Roussel":
			await _vue(c.global_position + Vector3(2.6, 1.5, -1.2), c.global_position + Vector3(0, 1.0, 0), "q7_sport")
	# 2. Équipe du FPT qui marche dans la remise
	var fp: Array = main.equipages["FPT"]
	for i in fp.size():
		fp[i].aller(fp[i].global_position + Vector3(-8.0, 0, 0))
	await _attendre(0.9)
	await _vue(fp[2].global_position + Vector3(-3.5, 1.5, 2.6), fp[2].global_position + Vector3(0, 1.0, 0), "q3_marche_fpt")
	# 3. Feu d'appartement : binôme capelé devant l'immeuble
	cam.clear_current(false)
	main.joueur.camera.make_current()
	main.force_scenario = "feu_appartement"
	main.prochain_appel = 0.0
	await _attendre(0.3)
	main._vestiaire()
	main._monter_depart()
	main.vitesse_test = 6.0
	while main.etat != "sur_place":
		await get_tree().process_frame
	main.vitesse_test = 1.0
	await _attendre(2.0)
	main._capeler()
	await _attendre(0.5)
	cam.make_current()
	var e = main.fpt
	var d: Vector3 = e.droite()
	var av: Vector3 = e.avant()
	var n = fp[2]
	n.arreter()
	n.teleporter(e.global_position + d * 2.6 + av * 1.0)
	n.rotation.y = atan2(-d.x, -d.z)
	await _vue(n.global_position + d * 2.4 + av * 0.9 + Vector3(0, 1.55, 0), n.global_position + Vector3(0, 1.2, 0), "q4_binome_ari")
	n.rotation.y = atan2(d.x, d.z)
	await _vue(n.global_position + d * 2.4 - av * 0.9 + Vector3(0, 1.55, 0), n.global_position + Vector3(0, 1.1, 0), "q5_ari_dos")
	await _vue(e.global_position + d * 4.6 - av * 5.5 + Vector3(0, 1.9, 0), e.global_position + d * 2.4 + Vector3(0, 1.1, 0), "q6_sur_place")
	get_tree().quit()


func _vue(pos: Vector3, cible: Vector3, nom: String) -> void:
	cam.global_position = pos
	cam.look_at(cible)
	await _attendre(0.4)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dossier + "/" + nom + ".png")


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout
