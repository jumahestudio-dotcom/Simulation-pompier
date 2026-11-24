## Plans vus de dessus, orthographiques (outil de développement).
##   godot --path . res://tests/plan_dessus.tscn : -- <dossier> nom:cx:cz:taille ...
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var dossier: String = args[0]
	DirAccess.make_dir_recursive_absolute(dossier)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.5).timeout
	if "hud" in main and main.hud is CanvasLayer:
		main.hud.visible = false
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.far = 500.0
	add_child(cam)
	cam.make_current()
	for a in args.slice(1):
		var p: PackedStringArray = a.split(":")
		cam.size = float(p[3])
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.global_position = Vector3(float(p[1]), 200, float(p[2]))
		cam.rotation = Vector3(-PI * 0.5, 0, 0)
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dossier + "/" + p[0] + ".png")
	get_tree().quit()
