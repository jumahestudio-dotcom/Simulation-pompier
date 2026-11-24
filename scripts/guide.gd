## Balise d'objectif : un chevron jaune qui flotte au-dessus de ce qu'il faut faire ensuite
## (vestiaire, engin, sac de secours, victime…), avec la distance. Visible de loin,
## elle grossit avec l'éloignement pour rester lisible.
extends Node3D

var _chevron: MeshInstance3D
var _colonne: MeshInstance3D
var _texte: Label3D
var _t := 0.0
var _base := Vector3.ZERO
var actif := false


func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.82, 0.1)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.75, 0.1)
	m.emission_energy_multiplier = 2.2
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = true
	m.render_priority = 10
	# Chevron pointe en bas (cône renversé)
	var c := CylinderMesh.new()
	c.top_radius = 0.32
	c.bottom_radius = 0.0
	c.height = 0.55
	c.radial_segments = 4
	c.material = m
	_chevron = MeshInstance3D.new()
	_chevron.mesh = c
	_chevron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_chevron)
	# Colonne de lumière légère, pour repérer l'objectif de loin
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(1.0, 0.85, 0.2, 0.18)
	mc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mc.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cc := CylinderMesh.new()
	cc.top_radius = 0.06
	cc.bottom_radius = 0.06
	cc.height = 40.0
	cc.radial_segments = 8
	cc.material = mc
	_colonne = MeshInstance3D.new()
	_colonne.mesh = cc
	_colonne.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_colonne)
	_texte = Label3D.new()
	_texte.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_texte.no_depth_test = true
	_texte.fixed_size = true
	_texte.pixel_size = 0.0011
	_texte.font_size = 30
	_texte.outline_size = 8
	_texte.modulate = Color(1.0, 0.9, 0.4)
	_texte.render_priority = 11
	_texte.outline_render_priority = 10
	add_child(_texte)
	visible = false


## Place la balise au-dessus du point donné (hauteur des yeux environ).
func cibler(pos: Vector3, libelle: String) -> void:
	_base = pos
	_texte.text = libelle
	actif = true
	visible = true


func cacher() -> void:
	actif = false
	visible = false


func _process(delta: float) -> void:
	if not actif:
		return
	_t += delta
	var cam := get_viewport().get_camera_3d()
	var d := 10.0
	if cam != null:
		d = cam.global_position.distance_to(_base)
	# Plus loin = plus gros et plus haut, pour rester visible au-dessus des toits.
	var k := clampf(d / 12.0, 0.6, 8.0)
	global_position = _base + Vector3(0, 0.9 + k * 0.5 + sin(_t * 3.0) * 0.12 * k, 0)
	_chevron.scale = Vector3.ONE * k
	_chevron.rotation.y = _t * 1.5
	_colonne.visible = d > 25.0
	_colonne.position = Vector3(0, 20.0, 0)
	_colonne.scale = Vector3(k, 1, k)
	_texte.position = Vector3(0, 0.55 * k, 0)
	_texte.text = _texte.text.get_slice("\n", 0) + ("\n%d m" % int(d) if d > 4.0 else "")
	# Trop près : on cache le chevron pour ne pas gêner la vue.
	_chevron.visible = d > 2.2
