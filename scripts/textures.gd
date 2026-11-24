## Textures fabriquées par le programme (aucun fichier image externe, donc aucun souci de droits).
## Façades en tuffeau avec fenêtres et volets, ardoise, asphalte, pavés, herbe, béton,
## et les petites images rondes qui servent au feu et à la fumée.
extends RefCounted

static var _textures: Dictionary = {}
static var _materiaux: Dictionary = {}


static func _bruit(l: int, h: int, freq: float, graine: int) -> Image:
	var n := FastNoiseLite.new()
	n.seed = graine
	n.frequency = freq
	n.fractal_octaves = 4
	var img: Image = n.get_seamless_image(l, h)
	img.convert(Image.FORMAT_RGBA8)
	return img


## Colore une image de bruit entre deux couleurs, avec des petits grains aléatoires.
static func _teinter(img: Image, a: Color, b: Color, grain: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in img.get_height():
		for x in img.get_width():
			var v: float = img.get_pixel(x, y).r
			var c: Color = a.lerp(b, v)
			if grain > 0.0:
				var g: float = rng.randf_range(-grain, grain)
				c = Color(c.r + g, c.g + g, c.b + g)
			img.set_pixel(x, y, c)


static func _rect(img: Image, x: int, y: int, l: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, l, h), c)


static func _finir(img: Image) -> ImageTexture:
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Façade : une travée de 4 m de large sur 3 m de haut (un étage), avec une fenêtre et ses volets.
static func facade() -> ImageTexture:
	if _textures.has("facade"):
		return _textures["facade"]
	var img := _bruit(256, 192, 0.04, 11)
	_teinter(img, Color(0.86, 0.84, 0.80), Color(0.98, 0.97, 0.94), 0.025)
	# Joints des pierres de tuffeau
	for y in range(0, 192, 24):
		_rect(img, 0, y, 256, 1, Color(0.80, 0.78, 0.74))
		var decal := 0 if (y / 24) % 2 == 0 else 32
		for x in range(decal, 256, 64):
			_rect(img, x, y, 1, 24, Color(0.82, 0.80, 0.76))
	# Bandeau d'étage
	_rect(img, 0, 0, 256, 7, Color(0.93, 0.92, 0.89))
	_rect(img, 0, 7, 256, 2, Color(0.75, 0.73, 0.69))
	# Linteau et appui
	_rect(img, 82, 34, 92, 10, Color(0.96, 0.95, 0.92))
	_rect(img, 84, 152, 88, 6, Color(0.96, 0.95, 0.92))
	_rect(img, 84, 158, 88, 2, Color(0.6, 0.58, 0.55))
	# Volets (gris-bleu, à lames)
	for vx in [50, 172]:
		_rect(img, vx, 44, 34, 108, Color(0.42, 0.50, 0.56))
		for y in range(46, 150, 6):
			_rect(img, vx + 2, y, 30, 2, Color(0.34, 0.41, 0.47))
	# Fenêtre : encadrement, vitres, petits bois
	_rect(img, 86, 44, 84, 108, Color(0.93, 0.93, 0.9))
	for y in range(50, 146):
		var t: float = float(y - 50) / 96.0
		_rect(img, 92, y, 72, 1, Color(0.30, 0.36, 0.43).lerp(Color(0.12, 0.15, 0.19), t))
	_rect(img, 126, 50, 4, 96, Color(0.93, 0.93, 0.9))
	_rect(img, 92, 82, 72, 3, Color(0.93, 0.93, 0.9))
	_rect(img, 92, 114, 72, 3, Color(0.93, 0.93, 0.9))
	# Reflet du ciel
	for i in 18:
		_rect(img, 98 + i, 56 + i, 6, 1, Color(0.55, 0.62, 0.7))
	var tex := _finir(img)
	_textures["facade"] = tex
	return tex


static func ardoise() -> ImageTexture:
	if _textures.has("ardoise"):
		return _textures["ardoise"]
	var img := _bruit(128, 128, 0.08, 3)
	_teinter(img, Color(0.22, 0.25, 0.29), Color(0.33, 0.36, 0.41), 0.03)
	for y in range(0, 128, 16):
		_rect(img, 0, y, 128, 2, Color(0.15, 0.17, 0.2))
		var decal := 0 if (y / 16) % 2 == 0 else 8
		for x in range(decal, 128, 16):
			_rect(img, x, y, 1, 16, Color(0.17, 0.19, 0.22))
	var tex := _finir(img)
	_textures["ardoise"] = tex
	return tex


static func asphalte() -> ImageTexture:
	if _textures.has("asphalte"):
		return _textures["asphalte"]
	var img := _bruit(256, 256, 0.03, 5)
	_teinter(img, Color(0.25, 0.25, 0.26), Color(0.36, 0.36, 0.37), 0.07)
	var tex := _finir(img)
	_textures["asphalte"] = tex
	return tex


static func paves() -> ImageTexture:
	if _textures.has("paves"):
		return _textures["paves"]
	var img := _bruit(128, 128, 0.06, 9)
	_teinter(img, Color(0.58, 0.57, 0.55), Color(0.70, 0.69, 0.66), 0.03)
	for i in range(0, 128, 32):
		_rect(img, i, 0, 2, 128, Color(0.45, 0.44, 0.42))
		_rect(img, 0, i, 128, 2, Color(0.45, 0.44, 0.42))
	var tex := _finir(img)
	_textures["paves"] = tex
	return tex


static func herbe() -> ImageTexture:
	if _textures.has("herbe"):
		return _textures["herbe"]
	var img := _bruit(256, 256, 0.05, 2)
	_teinter(img, Color(0.24, 0.34, 0.16), Color(0.40, 0.50, 0.25), 0.05)
	var tex := _finir(img)
	_textures["herbe"] = tex
	return tex


static func beton() -> ImageTexture:
	if _textures.has("beton"):
		return _textures["beton"]
	var img := _bruit(192, 192, 0.05, 4)
	_teinter(img, Color(0.78, 0.78, 0.76), Color(0.90, 0.90, 0.88), 0.03)
	_rect(img, 0, 0, 192, 2, Color(0.62, 0.62, 0.6))
	_rect(img, 0, 0, 2, 192, Color(0.62, 0.62, 0.6))
	var tex := _finir(img)
	_textures["beton"] = tex
	return tex


## Rideau de coffre d'engin (aluminium à lames verticales).
static func rideau() -> ImageTexture:
	if _textures.has("rideau"):
		return _textures["rideau"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.78, 0.79, 0.8))
	for x in range(0, 64, 4):
		_rect(img, x, 0, 1, 64, Color(0.55, 0.56, 0.58))
	var tex := _finir(img)
	_textures["rideau"] = tex
	return tex


## Chevrons rouges et jaunes (arrière des engins).
static func chevrons() -> ImageTexture:
	if _textures.has("chevrons"):
		return _textures["chevrons"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var bande := int(floor((x + y) / 16.0)) % 2
			img.set_pixel(x, y, Color(0.85, 0.05, 0.05) if bande == 0 else Color(1.0, 0.85, 0.0))
	var tex := _finir(img)
	_textures["chevrons"] = tex
	return tex


## Tache ronde douce (blanche au centre, transparente au bord) pour le feu et la fumée.
static func tache(douceur: float) -> ImageTexture:
	var cle := "tache%.2f" % douceur
	if _textures.has(cle):
		return _textures[cle]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.frequency = 0.12
	for y in 64:
		for x in 64:
			var d: float = Vector2(x - 31.5, y - 31.5).length() / 32.0
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, douceur)
			a *= 0.75 + 0.25 * n.get_noise_2d(x, y)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	var tex := _finir(img)
	_textures[cle] = tex
	return tex


## Façade d'immeuble des années 1970 : panneaux de béton, grande fenêtre, garde-corps de balcon.
static func facade_hlm() -> ImageTexture:
	if _textures.has("hlm"):
		return _textures["hlm"]
	var img := _bruit(192, 192, 0.05, 21)
	_teinter(img, Color(0.86, 0.85, 0.82), Color(0.95, 0.94, 0.92), 0.02)
	_rect(img, 0, 0, 192, 3, Color(0.6, 0.6, 0.6))
	_rect(img, 0, 0, 3, 192, Color(0.7, 0.7, 0.7))
	# Fenêtre
	_rect(img, 36, 40, 120, 90, Color(0.92, 0.92, 0.92))
	for y in range(46, 124):
		_rect(img, 42, y, 108, 1, Color(0.3, 0.36, 0.42).lerp(Color(0.12, 0.14, 0.18), float(y - 46) / 78.0))
	_rect(img, 94, 46, 4, 78, Color(0.92, 0.92, 0.92))
	# Garde-corps de balcon (couleur)
	_rect(img, 20, 130, 152, 40, Color(0.55, 0.35, 0.28))
	for x in range(24, 170, 8):
		_rect(img, x, 134, 2, 34, Color(0.45, 0.28, 0.22))
	var tex := _finir(img)
	_textures["hlm"] = tex
	return tex


## Bardage métallique ondulé (entrepôts, hangars).
static func bardage() -> ImageTexture:
	if _textures.has("bardage"):
		return _textures["bardage"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var v: float = 0.82 + 0.12 * sin(x / 64.0 * TAU * 8.0)
			img.set_pixel(x, y, Color(v, v, v))
	var tex := _finir(img)
	_textures["bardage"] = tex
	return tex


## Tuiles mécaniques (toits des pavillons).
static func tuiles() -> ImageTexture:
	if _textures.has("tuiles"):
		return _textures["tuiles"]
	var img := _bruit(64, 64, 0.1, 31)
	_teinter(img, Color(0.62, 0.3, 0.2), Color(0.75, 0.4, 0.27), 0.03)
	for y in range(0, 64, 8):
		_rect(img, 0, y, 64, 2, Color(0.45, 0.2, 0.13))
	for x in range(0, 64, 8):
		_rect(img, x, 0, 1, 64, Color(0.52, 0.25, 0.16))
	var tex := _finir(img)
	_textures["tuiles"] = tex
	return tex


## Façade de pavillon : crépi clair, une fenêtre avec volets (travée 3 m × 2,8 m).
static func crepi() -> ImageTexture:
	if _textures.has("crepi"):
		return _textures["crepi"]
	var img := _bruit(128, 128, 0.15, 41)
	_teinter(img, Color(0.9, 0.88, 0.83), Color(0.98, 0.97, 0.93), 0.04)
	_rect(img, 48, 34, 32, 44, Color(0.95, 0.95, 0.95))
	_rect(img, 51, 37, 26, 38, Color(0.2, 0.25, 0.3))
	_rect(img, 63, 37, 2, 38, Color(0.95, 0.95, 0.95))
	for vx in [34, 82]:
		_rect(img, vx, 34, 12, 44, Color(0.55, 0.42, 0.3))
	var tex := _finir(img)
	_textures["crepi"] = tex
	return tex


# ---------------------------------------------------------------------------
# Matériaux (avec mise en cache)
# ---------------------------------------------------------------------------

## Carte de relief (normal map) tirée de l'image : les parties sombres (joints, vitres) paraissent creusées.
static func normale(nom: String, tex: Texture2D, force: float) -> ImageTexture:
	var cle := "n|" + nom
	if _textures.has(cle):
		return _textures[cle]
	var img: Image = tex.get_image().duplicate()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	# Relief = luminosité (le calcul lit le canal rouge)
	for y in img.get_height():
		for x in img.get_width():
			var v: float = img.get_pixel(x, y).get_luminance()
			img.set_pixel(x, y, Color(v, v, v))
	img.bump_map_to_normal_map(force)
	var t := _finir(img)
	_textures[cle] = t
	return t


## Grandes taches claires/sombres (salissures, usure) qui cassent la répétition des textures.
static func macro() -> ImageTexture:
	if _textures.has("macro"):
		return _textures["macro"]
	var n := FastNoiseLite.new()
	n.seed = 77
	n.frequency = 0.012
	n.fractal_octaves = 5
	var img: Image = n.get_seamless_image(256, 256)
	img.convert(Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			var v: float = img.get_pixel(x, y).r
			var c: float = lerpf(0.8, 1.0, smoothstep(0.2, 0.8, v))
			img.set_pixel(x, y, Color(c, c, c * 0.985, 1.0))
	var t := _finir(img)
	_textures["macro"] = t
	return t


## Fine patine presque blanche, posée sur les objets de couleur unie.
static func salissure() -> ImageTexture:
	if _textures.has("salissure"):
		return _textures["salissure"]
	var img := _bruit(128, 128, 0.06, 91)
	_teinter(img, Color(0.84, 0.83, 0.81), Color(1.0, 1.0, 1.0), 0.03)
	var t := _finir(img)
	_textures["salissure"] = t
	return t


## Matériau « plaqué » sur le monde : la texture se répète selon la taille réelle (en mètres).
## "relief" : force de la carte de relief (0 = surface lisse).
static func plaque(nom: String, tex: Texture2D, metres_x: float, metres_y: float, teinte: Color = Color.WHITE, rugosite: float = 0.9, relief: float = 3.0) -> StandardMaterial3D:
	var cle := "%s|%s|%.2f|%.2f" % [nom, teinte.to_html(), metres_x, metres_y]
	if _materiaux.has(cle):
		return _materiaux[cle]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = teinte
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(1.0 / metres_x, 1.0 / metres_y, 1.0 / metres_x)
	m.roughness = rugosite
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if relief > 0.0:
		m.normal_enabled = true
		m.normal_texture = normale(nom, tex, relief)
		m.normal_scale = 1.0
	# Usure et salissures à grande échelle (environ 35 m), pour éviter l'effet « papier peint ».
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.detail_albedo = macro()
	m.uv2_triplanar = true
	m.uv2_world_triplanar = true
	m.uv2_scale = Vector3.ONE / 35.0
	_materiaux[cle] = m
	return m


static func mat_facade(teinte: Color) -> StandardMaterial3D:
	return plaque("facade", facade(), 4.0, 3.0, teinte)


static func mat_ardoise() -> StandardMaterial3D:
	return plaque("ardoise", ardoise(), 2.0, 2.0, Color.WHITE, 0.55, 4.0)


static func mat_asphalte() -> StandardMaterial3D:
	return plaque("asphalte", asphalte(), 6.0, 6.0, Color.WHITE, 0.92, 2.0)


static func mat_paves() -> StandardMaterial3D:
	return plaque("paves", paves(), 1.5, 1.5, Color.WHITE, 0.85, 5.0)


static func mat_herbe() -> StandardMaterial3D:
	return plaque("herbe", herbe(), 8.0, 8.0, Color.WHITE, 0.95, 2.0)


static func mat_beton(teinte: Color = Color.WHITE) -> StandardMaterial3D:
	return plaque("beton", beton(), 3.0, 3.0, teinte)


## Peinture de carrosserie (un peu brillante).
static func carrosserie(c: Color) -> StandardMaterial3D:
	var cle := "carro|" + c.to_html()
	if _materiaux.has(cle):
		return _materiaux[cle]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.3
	m.roughness = 0.32
	# Vernis : reflet net par-dessus la peinture, comme une vraie carrosserie.
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	m.clearcoat_roughness = 0.12
	_materiaux[cle] = m
	return m


static func vitre() -> StandardMaterial3D:
	if _materiaux.has("vitre"):
		return _materiaux["vitre"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.11, 0.14)
	m.metallic = 0.6
	m.roughness = 0.08
	_materiaux["vitre"] = m
	return m


static func emissif(c: Color, energie: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energie
	return m


# ---------------------------------------------------------------------------
# Matériaux des façades en relief (fenêtres en vrai 3D posées par details.gd)
# ---------------------------------------------------------------------------

## Pierre de taille (tuffeau) sans fenêtres : assises de 40 cm, joints décalés, bandeau tous les 3 m.
static func pierre_taille() -> ImageTexture:
	if _textures.has("pierre_taille"):
		return _textures["pierre_taille"]
	var img := _bruit(256, 192, 0.05, 23)
	_teinter(img, Color(0.85, 0.83, 0.79), Color(0.99, 0.98, 0.95), 0.03)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# Pierres légèrement différentes les unes des autres
	for y in range(0, 192, 24):
		var decal := 0 if (y / 24) % 2 == 0 else 32
		for x in range(decal - 64, 256, 64):
			var d := rng.randf_range(-0.035, 0.035)
			for yy in range(y + 1, y + 24):
				for xx in range(maxi(x + 1, 0), mini(x + 64, 256)):
					var c := img.get_pixel(xx, yy)
					img.set_pixel(xx, yy, Color(c.r + d, c.g + d, c.b + d * 1.2))
		_rect(img, 0, y, 256, 1, Color(0.76, 0.74, 0.7))
		for x in range(decal, 256, 64):
			_rect(img, x, y, 1, 24, Color(0.78, 0.76, 0.72))
	var tex := _finir(img)
	_textures["pierre_taille"] = tex
	return tex


## Brique rouge-orangé avec joints clairs.
static func brique() -> ImageTexture:
	if _textures.has("brique"):
		return _textures["brique"]
	var img := _bruit(256, 256, 0.08, 31)
	_teinter(img, Color(0.5, 0.24, 0.16), Color(0.7, 0.36, 0.24), 0.05)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for y in range(0, 256, 16):
		var decal := 0 if (y / 16) % 2 == 0 else 24
		for x in range(decal - 48, 256, 48):
			var d := rng.randf_range(-0.08, 0.06)
			for yy in range(y + 2, y + 16):
				for xx in range(maxi(x + 2, 0), mini(x + 48, 256)):
					var c := img.get_pixel(xx, yy)
					img.set_pixel(xx, yy, Color(c.r + d, c.g + d * 0.8, c.b + d * 0.6))
		_rect(img, 0, y, 256, 2, Color(0.78, 0.74, 0.68))
		for x in range(decal, 256, 48):
			_rect(img, x, y, 2, 16, Color(0.78, 0.74, 0.68))
	var tex := _finir(img)
	_textures["brique"] = tex
	return tex


## Enduit taloché, sans motif.
static func enduit() -> ImageTexture:
	if _textures.has("enduit"):
		return _textures["enduit"]
	var img := _bruit(256, 256, 0.12, 47)
	_teinter(img, Color(0.88, 0.88, 0.87), Color(1.0, 1.0, 1.0), 0.045)
	var tex := _finir(img)
	_textures["enduit"] = tex
	return tex


## Lames de persiennes (blanc, à teinter).
static func volet() -> ImageTexture:
	if _textures.has("volet"):
		return _textures["volet"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.95, 0.95, 0.95))
	for y in range(0, 64, 8):
		_rect(img, 0, y + 5, 64, 2, Color(0.62, 0.62, 0.62))
		_rect(img, 0, y + 7, 64, 1, Color(0.8, 0.8, 0.8))
	var tex := _finir(img)
	_textures["volet"] = tex
	return tex


## Feuillage : touffes claires et sombres, pour que les arbres ne soient pas des boules lisses.
static func feuillage() -> ImageTexture:
	if _textures.has("feuillage"):
		return _textures["feuillage"]
	var img := _bruit(256, 256, 0.09, 61)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for y in 256:
		for x in 256:
			var v: float = img.get_pixel(x, y).r
			v = clampf(v * 1.6 - 0.3 + rng.randf_range(-0.25, 0.25), 0.0, 1.0)
			img.set_pixel(x, y, Color(0.45, 0.45, 0.45).lerp(Color(1.15, 1.15, 1.1), v))
	var tex := _finir(img)
	_textures["feuillage"] = tex
	return tex


static func mat_pierre_taille(teinte: Color) -> StandardMaterial3D:
	return plaque("pierre_taille", pierre_taille(), 3.2, 2.4, teinte, 0.9, 3.0)


static func mat_brique() -> StandardMaterial3D:
	return plaque("brique", brique(), 1.15, 1.15, Color.WHITE, 0.9, 4.0)


static func mat_enduit(teinte: Color) -> StandardMaterial3D:
	return plaque("enduit", enduit(), 2.0, 2.0, teinte, 0.95, 2.0)


static func mat_volet(teinte: Color) -> StandardMaterial3D:
	return plaque("volet", volet(), 0.5, 0.5, teinte, 0.7, 3.0)


static func mat_feuillage(teinte: Color) -> StandardMaterial3D:
	return plaque("feuillage", feuillage(), 1.6, 1.6, teinte, 0.95, 6.0)


static func mat_zinc() -> StandardMaterial3D:
	return plaque("zinc", enduit(), 0.6, 4.0, Color(0.3, 0.33, 0.36), 0.75, 1.0)


## Vitrage : sombre et réfléchissant ; quelques teintes pour que les fenêtres ne soient pas toutes pareilles.
static func vitrage(k: int) -> StandardMaterial3D:
	var cle := "vitrage%d" % k
	if _materiaux.has(cle):
		return _materiaux[cle]
	var teintes: Array = [Color(0.07, 0.09, 0.12), Color(0.1, 0.12, 0.15), Color(0.05, 0.06, 0.08), Color(0.13, 0.14, 0.15)]
	var m := StandardMaterial3D.new()
	m.albedo_color = teintes[k % teintes.size()]
	m.metallic = 0.55
	m.roughness = 0.05 + 0.04 * (k % 3)
	_materiaux[cle] = m
	return m
