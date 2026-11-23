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
	_teinter(img, Color(0.17, 0.17, 0.18), Color(0.27, 0.27, 0.28), 0.06)
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


# ---------------------------------------------------------------------------
# Matériaux (avec mise en cache)
# ---------------------------------------------------------------------------

## Matériau « plaqué » sur le monde : la texture se répète selon la taille réelle (en mètres).
static func plaque(nom: String, tex: Texture2D, metres_x: float, metres_y: float, teinte: Color = Color.WHITE, rugosite: float = 0.9) -> StandardMaterial3D:
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
	_materiaux[cle] = m
	return m


static func mat_facade(teinte: Color) -> StandardMaterial3D:
	return plaque("facade", facade(), 4.0, 3.0, teinte)


static func mat_ardoise() -> StandardMaterial3D:
	return plaque("ardoise", ardoise(), 2.0, 2.0, Color.WHITE, 0.6)


static func mat_asphalte() -> StandardMaterial3D:
	return plaque("asphalte", asphalte(), 6.0, 6.0, Color.WHITE, 0.95)


static func mat_paves() -> StandardMaterial3D:
	return plaque("paves", paves(), 1.5, 1.5)


static func mat_herbe() -> StandardMaterial3D:
	return plaque("herbe", herbe(), 8.0, 8.0)


static func mat_beton(teinte: Color = Color.WHITE) -> StandardMaterial3D:
	return plaque("beton", beton(), 3.0, 3.0, teinte)


## Peinture de carrosserie (un peu brillante).
static func carrosserie(c: Color) -> StandardMaterial3D:
	var cle := "carro|" + c.to_html()
	if _materiaux.has(cle):
		return _materiaux[cle]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.25
	m.roughness = 0.35
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
