## Quelques captures seulement, pour régler la lumière vite (outil de développement).
##   godot --path . res://tests/capture_rapide.tscn -- <dossier>
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
	main.joueur.teleporter(Vector3(-250, 0.2, 10), PI * 0.15)
	await _attendre(0.5)
	await _photo("2_boulevard")
	var cam := Camera3D.new()
	cam.far = 3000.0
	add_child(cam)
	cam.make_current()
	for v in [["8_centre_ancien", Vector3(-120, 45, 60), Vector3(-20, 0, -40)], ["14_rue_commercante", Vector3(-165, 1.8, -4), Vector3(-125, 3.5, -16)]]:
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
