## Studio : les tenues du pompier 3D côte à côte (outil de développement).
##   godot --path . res://tests/studio_tenues.tscn -- <dossier>
extends Node3D
const P3 = preload("res://scripts/pompier3d.gd")
const Corps = preload("res://scripts/corps.gd")
const S = preload("res://scripts/sdis37.gd")

const ORDRE := ["station", "station_F", "sport", "sport_F", "ceremonie", "intervention", "secours_routier", "incendie", "incendie_ari"]

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
	var pm := PlaneMesh.new(); pm.size = Vector2(60, 60)
	sol.mesh = pm
	add_child(sol)
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-45, 20, 0)
	soleil.shadow_enabled = true
	add_child(soleil)
	var gens: Array = []
	for i in ORDRE.size():
		var rng := RandomNumberGenerator.new()
		rng.seed = 300 + i * 11
		var p = P3.new()
		add_child(p)
		var t := Corps.tenue_pompier(rng, "f1")
		var c: String = ORDRE[i]
		t["sexe"] = "F" if c.ends_with("_F") else "M"
		c = c.trim_suffix("_F")
		p.construire(t, P3.fichier_civil(c, t["sexe"]))
		p.habiller(c.trim_suffix("_ari"))
		p.equiper(c.begins_with("incendie") or c == "secours_routier", c == "incendie_ari")
		p.position = Vector3(-(ORDRE.size() - 1) * 0.55 + i * 1.1, 0, 0)
		gens.append(p)
	# Les modèles de Sellier, au second rang, pour comparer les couleurs
	var refs := ["station", "", "sport", "", "ceremonie", "", "secours_routier", "incendie"]
	for i in refs.size():
		if refs[i] == "":
			continue
		var m := S.instance(S.TENUES[refs[i]])
		if m != null:
			add_child(m)
			m.position = Vector3(-(ORDRE.size() - 1) * 0.55 + i * 1.1, 0, 2.2)
	var cam := Camera3D.new()
	cam.fov = 38
	add_child(cam)
	cam.make_current()
	var vues := [["face", Vector3(0, 1.5, -12.0), Vector3(0, 0.9, 0)], ["dos", Vector3(0, 1.5, 7.0), Vector3(0, 0.9, 0)], ["3q", Vector3(-7.0, 1.6, -7.0), Vector3(0, 0.9, 0)], ["civils", Vector3(-3.3, 1.5, -4.2), Vector3(-3.3, 1.0, 0)]]
	for v in vues:
		for p in gens:
			p.animer(0.0, 0.0)
		cam.global_position = v[1]
		cam.look_at(v[2])
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/tenues_%s.png" % [dossier, v[0]])
	get_tree().quit()
