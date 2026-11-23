## Le joueur : un sapeur 2e classe vu à la première personne.
extends CharacterBody3D

var camera: Camera3D
var vitesse := 4.3
var sensibilite := 0.0025
var controle := true
var tenue := ""        # "", "suap" (tenue d'intervention), "feu" (tenue de feu)
var ari := false       # appareil respiratoire isolant capelé
var air := 300.0       # pression de la bouteille en bars
var lance := false     # lance à incendie en main
var sante := 100.0
var porte_victime := false
var jet: CPUParticles3D
var _tangage := 0.0


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.65, 0)
	camera.fov = 75.0
	camera.far = 1500.0
	add_child(camera)
	camera.current = true
	floor_snap_length = 0.3
	_creer_jet()


func _creer_jet() -> void:
	jet = CPUParticles3D.new()
	jet.amount = 200
	jet.lifetime = 0.8
	jet.emitting = false
	jet.local_coords = false
	var sm := SphereMesh.new()
	sm.radius = 0.025
	sm.height = 0.05
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.9, 1.0, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = m
	jet.mesh = sm
	jet.direction = Vector3(0, 0, -1)
	jet.spread = 4.0
	jet.initial_velocity_min = 13.0
	jet.initial_velocity_max = 15.0
	jet.gravity = Vector3(0, -6.0, 0)
	jet.position = Vector3(0.2, -0.35, -1.5)
	camera.add_child(jet)


func _unhandled_input(event: InputEvent) -> void:
	if not controle:
		return
	var mm := event as InputEventMouseMotion
	if mm != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-mm.relative.x * sensibilite)
		_tangage = clampf(_tangage - mm.relative.y * sensibilite, -1.4, 1.4)
		camera.rotation.x = _tangage


func activer(v: bool) -> void:
	controle = v
	visible = v
	set_physics_process(v)
	if v:
		camera.current = true
	else:
		jet.emitting = false


func teleporter(pos: Vector3, angle: float) -> void:
	global_position = pos
	rotation.y = angle
	velocity = Vector3.ZERO


func direction_regard() -> Vector3:
	return -camera.global_transform.basis.z


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	var dir := Vector3.ZERO
	if controle:
		var e := Input.get_vector("gauche", "droite", "avancer", "reculer")
		dir = transform.basis * Vector3(e.x, 0.0, e.y)
		dir.y = 0.0
		dir = dir.normalized()
	var v := vitesse
	if Input.is_action_pressed("courir"):
		v *= 1.7
	if ari:
		v *= 0.8
	if porte_victime:
		v *= 0.55
	velocity.x = dir.x * v
	velocity.z = dir.z * v
	move_and_slide()
