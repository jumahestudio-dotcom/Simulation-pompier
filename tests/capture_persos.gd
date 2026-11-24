## Captures des personnages (pompiers, victimes, passants) pour vérifier le modèle (outil de développement).
##   godot --path . res://tests/capture_persos.tscn -- <dossier_de_sortie>
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
	var o := Vector3(-150, 0, 4)
	var eq: Array = main.equipages["FPT"] + main.equipages["VSAV"]
	for i in eq.size():
		var c = eq[i]
		c.visible = true
		c.teleporter(o + Vector3(-3.5 + i * 1.0, 0, 0))
		c.rotation.y = 0.0
		c.arreter()
	eq[0].set_casque(true)
	eq[1].set_casque(true)
	eq[2].set_ari(true)
	var cam := Camera3D.new()
	cam.near = 0.03
	cam.fov = 50.0
	add_child(cam)
	cam.make_current()
	await _attendre(0.6)
	await _vue_monde(cam, o + Vector3(0.0, 1.5, -6.5), o + Vector3(0, 1.0, 0), "p1_equipe")
	await _vue_monde(cam, o + Vector3(-1.2, 1.7, -1.6), o + Vector3(-1.5, 1.55, 0), "p2_visages")
	eq[2].rotation.y = PI
	await _attendre(0.2)
	await _vue_monde(cam, o + Vector3(-1.5, 1.6, 2.6), o + Vector3(-1.5, 1.2, 0), "p3_ari_dos")
	# Marche : deux collègues partent, capture en plein pas
	eq[5].aller(o + Vector3(1.5, 0, -30))
	eq[6].aller(o + Vector3(2.5, 0, -30))
	await _attendre(0.7)
	await _vue_monde(cam, eq[5].global_position + Vector3(4.0, 1.3, -1.0), eq[5].global_position + Vector3(0.5, 0.9, 0), "p4_marche")
	# Victime allongée et passants
	var Victime = load("res://scripts/victime.gd")
	var vic = Victime.new()
	main.add_child(vic)
	vic.construire("Martin", 67, "F")
	vic.configurer("cardiaque")
	vic.global_position = o + Vector3(0, 0, 4.0)
	await _attendre(0.3)
	await _vue_monde(cam, o + Vector3(2.0, 1.6, 5.5), o + Vector3(0, 0.1, 4.0), "p5_victime")
	var vic2 = Victime.new()
	main.add_child(vic2)
	vic2.construire("Durand", 24, "M")
	vic2.configurer("epilepsie")
	vic2.faits.append("pls")
	vic2._appliquer_posture()
	vic2.global_position = o + Vector3(3.0, 0, 4.0)
	await _attendre(0.3)
	await _vue_monde(cam, o + Vector3(4.6, 1.4, 5.8), o + Vector3(3.0, 0.2, 4.0), "p6_pls")
	cam.fov = 60.0
	var pietons: Array = []
	for n in main.get_children():
		if n.get_script() == load("res://scripts/pieton.gd"):
			pietons.append(n)
	for i in 3:
		var p = pietons[i * 7 % pietons.size()]
		var d: Vector3 = (p.arrivee - p.depart).normalized()
		var lat := Vector3(-d.z, 0, d.x)
		await _vue_monde(cam, p.global_position + lat * 3.5 + d * 2.0 + Vector3(0, 1.5, 0), p.global_position + Vector3(0, 1.0, 0), "p%d_passant" % (7 + i))
	get_tree().quit()


func _vue_monde(cam: Camera3D, pos: Vector3, cible: Vector3, nom: String) -> void:
	cam.global_position = pos
	cam.look_at(cible)
	await _attendre(0.3)
	await _photo(nom)


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
