## Studio : photographie des modèles isolés (outil de développement).
##   godot --path . res://tests/studio_modeles.tscn  -- <dossier> fichier[|garder][@echelle] ...
extends Node3D
const M = preload("res://scripts/modeles3d.gd")

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
	var ms := StandardMaterial3D.new(); ms.albedo_color = Color(0.45, 0.45, 0.43)
	sol.material_override = ms
	add_child(sol)
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-50, 35, 0)
	soleil.shadow_enabled = true
	add_child(soleil)
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	var k := 0
	for a in args.slice(1):
		var s := 1.0
		var nom: String = a
		if a.contains("@"):
			s = float(a.split("@")[1]); nom = a.split("@")[0]
		var garder := ""
		if nom.contains("|"):
			garder = nom.split("|")[1]; nom = nom.split("|")[0]
		var t0 := Time.get_ticks_msec()
		var inst: Node3D
		if nom.begins_with("trafic:"):
			inst = Node3D.new(); add_child(inst)
			M.voiture_trafic(inst, nom.trim_prefix("trafic:"), Color(0.2, 0.3, 0.6))
			nom = M.VOITURES_TRAFIC[nom.trim_prefix("trafic:")]["f"]
		else:
			inst = M.poser(self, nom, Vector3.ZERO, 0.0, s, garder, false)
		print(nom, " chargé en ", Time.get_ticks_msec() - t0, " ms")
		if inst == null:
			continue
		var bb := M.boite(nom, garder)
		print("aabb ", nom, " ", bb)
		var r := bb.size.length() * s * 0.75 + 0.5
		var h := bb.size.y * s * 0.5
		var vues := [["avant+z", Vector3(0, 0.25, 1)], ["arriere-z", Vector3(0, 0.25, -1)], ["cote+x", Vector3(1, 0.2, 0)], ["3q", Vector3(0.8, 0.5, 0.8)]]
		if args.size() > 4:
			vues = [vues[3]]
		for v in vues:
			cam.global_position = Vector3(0, h, 0) + (v[1] as Vector3).normalized() * r * 0.85
			cam.look_at(Vector3(0, h, 0))
			for i in 4:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%02d_%s_%s.png" % [dossier, k, nom.get_basename().left(20), v[0]])
		inst.queue_free()
		k += 1
	get_tree().quit()
