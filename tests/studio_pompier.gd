## Studio : le pompier 3D isolé (outil de développement).
##   godot --path . res://tests/studio_pompier.tscn -- <dossier>
extends Node3D
const P3 = preload("res://scripts/pompier3d.gd")
const Corps = preload("res://scripts/corps.gd")

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var dossier: String = args[0]
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
	var pm := PlaneMesh.new(); pm.size = Vector2(40, 40)
	sol.mesh = pm
	add_child(sol)
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-50, 35, 0)
	soleil.shadow_enabled = true
	add_child(soleil)
	if args.size() > 1:
		P3.BAISSE_BRAS = float(args[1])
	var gens: Array = []
	for i in 4:
		var rng := RandomNumberGenerator.new()
		rng.seed = 100 + i * 7
		var p = P3.new()
		add_child(p)
		p.construire(Corps.tenue_pompier(rng, "f1"))
		p.position = Vector3(-1.8 + i * 1.2, 0, 0)
		gens.append(p)
	gens[1].equiper(true, false)
	gens[2].equiper(true, true)
	var ref = Corps.new()
	add_child(ref)
	var rng2 := RandomNumberGenerator.new()
	ref.construire(Corps.tenue_pompier(rng2, "f1"))
	ref.position = Vector3(3.0, 0, 0)
	var cam := Camera3D.new()
	cam.fov = 40
	add_child(cam)
	cam.make_current()
	var vues := [["face", Vector3(0.6, 1.2, -6.0), Vector3(0.6, 0.9, 0), 0.0], ["cote", Vector3(6.0, 1.2, 0), Vector3(0, 0.9, 0), 0.0], ["dos", Vector3(0.6, 1.4, 6.0), Vector3(0.6, 0.9, 0), 0.0], ["marche", Vector3(5.0, 1.2, -2.0), Vector3(0, 0.9, 0), 1.4], ["visage", Vector3(-1.8, 1.65, -1.3), Vector3(-1.8, 1.6, 0), 0.0], ["buste", Vector3(-0.6, 1.3, -2.2), Vector3(-0.6, 1.1, 0), 0.0], ["profil", Vector3(-6.0, 1.1, 0.0), Vector3(0, 1.0, 0), 0.0]]
	for v in vues:
		for p in gens:
			p.animer(v[3], 0.25 if v[3] > 0 else 0.0)
		cam.global_position = v[1]
		cam.look_at(v[2])
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dossier, v[0]])
	get_tree().quit()
