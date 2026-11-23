## Captures des voitures (les cinq modèles) pour vérifier le modèle (outil de développement).
##   godot --path . res://tests/capture_voitures.tscn -- <dossier_de_sortie>
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
	var VM = load("res://scripts/voiture_modele.gd")
	var o := Vector3(-150, 0, 3)
	var couleurs: Array = [Color(0.75, 0.75, 0.78), Color(0.6, 0.08, 0.08), Color(0.12, 0.2, 0.4), Color(0.95, 0.95, 0.95), Color(0.15, 0.15, 0.16)]
	var types: Array = ["citadine", "berline", "break", "monospace", "utilitaire"]
	for i in types.size():
		var n: Node3D = VM.instancier(main, types[i], couleurs[i])
		n.global_position = o + Vector3(-9.0 + i * 4.5, 0, 0)
		n.rotation.y = PI * 0.5
	var cam := Camera3D.new()
	cam.near = 0.05
	cam.fov = 55.0
	add_child(cam)
	cam.make_current()
	await _attendre(0.5)
	for v in [["c1_rangee", o + Vector3(0, 2.2, -12.0), o + Vector3(0, 0.6, 0)],
			["c2_trois_quarts", o + Vector3(-14.0, 1.6, -4.5), o + Vector3(-6.0, 0.7, 0)],
			["c3_proche", o + Vector3(-2.0, 1.4, -4.2), o + Vector3(-4.5, 0.8, 0)],
			["c4_arriere", o + Vector3(11.0, 1.6, 4.5), o + Vector3(6.0, 0.7, 0)],
			["c5_rue", Vector3(-160, 1.7, -2), Vector3(-120, 0.8, -6)],
			["c6_garees", Vector3(-46.0, 1.7, -40), Vector3(-48.0, 0.6, -60)]]:
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
