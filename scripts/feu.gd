## Simulation du feu dans l'appartement du 2e étage.
## Chaque pièce est une "cellule" : le feu y grandit, enfume, puis passe à la pièce voisine.
## L'eau de la lance le fait reculer.
extends Node3D

const X0 := -40.7
const X1 := -23.3
const Y0 := 6.1
const Y1 := 9.4

var pieces: Array = []   # liste de dictionnaires
var _t := 0.0


func preparer() -> void:
	var defs: Array = [
		["Palier", -109.7, -104.0, false],
		["Entrée", -104.0, -98.0, true],
		["Séjour", -98.0, -90.0, true],
		["Cuisine", -90.0, -85.0, true],
		["Chambre", -85.0, -80.3, true],
	]
	for d in defs:
		var z0: float = d[1]
		var z1: float = d[2]
		var p: Dictionary = {
			"nom": d[0], "z0": z0, "z1": z1, "combustible": d[3],
			"intensite": 0.0, "fumee": 0.0, "chaleur": 0.0, "arrosee": false,
		}
		var centre := Vector3((X0 + X1) * 0.5, Y0, (z0 + z1) * 0.5)
		p["centre"] = centre
		p["flammes"] = _flammes(centre, Vector3((X1 - X0) * 0.35, 0.2, (z1 - z0) * 0.35))
		p["fumee_fx"] = _fumee(centre + Vector3(0, 2.6, 0), Vector3((X1 - X0) * 0.45, 0.3, (z1 - z0) * 0.45))
		var lum := OmniLight3D.new()
		lum.light_color = Color(1.0, 0.5, 0.15)
		lum.omni_range = 9.0
		lum.light_energy = 0.0
		lum.shadow_enabled = false
		lum.position = centre + Vector3(0, 1.2, 0)
		add_child(lum)
		p["lumiere"] = lum
		pieces.append(p)


func reinitialiser() -> void:
	for p in pieces:
		p["intensite"] = 0.0
		p["fumee"] = 0.0
		p["chaleur"] = 0.0
	_maj_visuels()


func allumer(nom_piece: String, valeur: float) -> void:
	for p in pieces:
		if p["nom"] == nom_piece:
			p["intensite"] = valeur


func enfumer(nom_piece: String, valeur: float) -> void:
	for p in pieces:
		if p["nom"] == nom_piece:
			p["fumee"] = valeur


func index_a(pos: Vector3) -> int:
	if pos.y < Y0 - 0.5 or pos.y > Y1 + 0.5 or pos.x < X0 - 0.3 or pos.x > X1 + 0.3:
		return -1
	for i in pieces.size():
		var p: Dictionary = pieces[i]
		if pos.z >= p["z0"] and pos.z < p["z1"]:
			return i
	return -1


func fumee_a(pos: Vector3) -> float:
	var i := index_a(pos)
	if i < 0:
		return 0.0
	return pieces[i]["fumee"]


func chaleur_a(pos: Vector3) -> float:
	var i := index_a(pos)
	if i < 0:
		return 0.0
	return pieces[i]["intensite"]


func nom_piece_a(pos: Vector3) -> String:
	var i := index_a(pos)
	if i < 0:
		return ""
	return pieces[i]["nom"]


func total_intensite() -> float:
	var t := 0.0
	for p in pieces:
		t += p["intensite"]
	return t


func eteint() -> bool:
	return total_intensite() <= 0.0


func pieces_en_feu() -> Array:
	var r: Array = []
	for p in pieces:
		if p["intensite"] > 0.0:
			r.append(p["nom"])
	return r


## L'eau part de "origine" dans la direction "dir" sur "portee" mètres.
## Renvoie le nom de la pièce touchée qui brûle, ou "".
func arroser(origine: Vector3, dir: Vector3, portee: float, delta: float) -> String:
	var d := 0.5
	while d <= portee:
		var pt: Vector3 = origine + dir * d
		var i := index_a(pt)
		if i >= 0:
			var p: Dictionary = pieces[i]
			if p["intensite"] > 0.0:
				p["intensite"] = maxf(0.0, p["intensite"] - 7.0 * delta)
				p["arrosee"] = true
				p["fumee"] = minf(100.0, p["fumee"] + 4.0 * delta)  # vapeur
				return p["nom"]
		d += 0.5
	return ""


func evoluer(delta: float) -> void:
	_t += delta
	var n := pieces.size()
	for i in n:
		var p: Dictionary = pieces[i]
		var inten: float = p["intensite"]
		if inten > 0.0 and not p["arrosee"]:
			p["intensite"] = minf(100.0, inten + 1.4 * delta)
		p["arrosee"] = false
		# Propagation vers les pièces voisines.
		if inten > 55.0:
			for j in [i - 1, i + 1]:
				if j < 0 or j >= n:
					continue
				var v: Dictionary = pieces[j]
				if v["combustible"] and v["intensite"] <= 0.0:
					v["chaleur"] = v["chaleur"] + delta * inten / 100.0
					if v["chaleur"] > 28.0:
						v["intensite"] = 8.0
						v["chaleur"] = 0.0
		# Fumée : elle monte vite près du feu et se répand dans les pièces voisines.
		var source: float = inten
		for j in [i - 1, i + 1]:
			if j >= 0 and j < n:
				source = maxf(source, pieces[j]["fumee"] * 0.85)
		var fum: float = p["fumee"]
		if source > fum:
			p["fumee"] = minf(100.0, fum + (source - fum) * 0.08 * delta * 4.0)
		else:
			p["fumee"] = maxf(0.0, fum - 0.6 * delta)
	_maj_visuels()


func _maj_visuels() -> void:
	for p in pieces:
		var inten: float = p["intensite"]
		var fl: CPUParticles3D = p["flammes"]
		fl.emitting = inten > 0.0
		var s: float = 0.4 + inten / 100.0 * 1.3
		fl.scale_amount_min = s * 0.6
		fl.scale_amount_max = s
		var lum: OmniLight3D = p["lumiere"]
		lum.light_energy = 0.0 if inten <= 0.0 else (1.5 + inten / 25.0 + sin(_t * 17.0) * 0.4)
		var fu: CPUParticles3D = p["fumee_fx"]
		fu.emitting = p["fumee"] > 8.0


func _flammes(pos: Vector3, etendue: Vector3) -> CPUParticles3D:
	var c := CPUParticles3D.new()
	c.position = pos
	c.amount = 70
	c.lifetime = 0.9
	c.emitting = false
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = m
	c.mesh = sm
	c.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	c.emission_box_extents = etendue
	c.direction = Vector3.UP
	c.spread = 15.0
	c.gravity = Vector3(0, 2.5, 0)
	c.initial_velocity_min = 0.6
	c.initial_velocity_max = 1.6
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.9, 0.3, 1.0))
	g.set_color(1, Color(0.8, 0.1, 0.0, 0.0))
	g.add_point(0.5, Color(1.0, 0.45, 0.05, 0.9))
	c.color_ramp = g
	add_child(c)
	return c


func _fumee(pos: Vector3, etendue: Vector3) -> CPUParticles3D:
	var c := CPUParticles3D.new()
	c.position = pos
	c.amount = 60
	c.lifetime = 3.0
	c.emitting = false
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = m
	c.mesh = sm
	c.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	c.emission_box_extents = etendue
	c.direction = Vector3(1, 0, 0)
	c.spread = 180.0
	c.gravity = Vector3(0, 0.05, 0)
	c.initial_velocity_min = 0.1
	c.initial_velocity_max = 0.4
	c.scale_amount_min = 1.0
	c.scale_amount_max = 2.2
	var g := Gradient.new()
	g.set_color(0, Color(0.15, 0.15, 0.15, 0.0))
	g.set_color(1, Color(0.1, 0.1, 0.1, 0.0))
	g.add_point(0.3, Color(0.18, 0.18, 0.18, 0.35))
	c.color_ramp = g
	add_child(c)
	return c
