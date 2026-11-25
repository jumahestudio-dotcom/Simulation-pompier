## Photos des modèles SDIS37 isolés :  godot --path . res://tests/studio_sdis37.tscn -- <dossier> fichier...
extends Node3D
const S = preload("res://scripts/sdis37.gd")

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var dossier: String = args[0]
	DirAccess.make_dir_recursive_absolute(dossier)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.68, 0.74)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.72, 0.75)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(200, 200)
	sol.mesh = pm
	add_child(sol)
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-50, 35, 0)
	soleil.shadow_enabled = true
	add_child(soleil)
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	var k := 0
	for nom in args.slice(1):
		var inst := S.instance(nom)
		if inst == null:
			print("absent ", nom); continue
		add_child(inst)
		await get_tree().process_frame
		var bb := AABB()
		var premier := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			bb = b if premier else bb.merge(b)
			premier = false
		print("aabb ", nom, " ", bb)
		var c := bb.get_center()
		var r := bb.size.length() * 0.9 + 0.3
		for v in [["avant", Vector3(0.15, 0.2, -1)], ["3q", Vector3(0.8, 0.5, 0.8)], ["arriere", Vector3(-0.2, 0.25, 1)]]:
			cam.global_position = c + (v[1] as Vector3).normalized() * r
			cam.look_at(c)
			for i in 4:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%02d_%s_%s.png" % [dossier, k, nom.get_basename().left(24), v[0]])
		inst.queue_free()
		k += 1
	get_tree().quit()
