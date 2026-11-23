## Script principal : construit le monde et fait vivre la garde.
## Déroulé d'une intervention : appel -> habillage -> départ -> trajet -> sur les lieux
## -> (transport à l'hôpital) -> retour -> note de fin.
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Carte = preload("res://scripts/carte.gd")
const Monde = preload("res://scripts/monde.gd")
const Joueur = preload("res://scripts/joueur.gd")
const Engin = preload("res://scripts/engin.gd")
const Trafic = preload("res://scripts/trafic.gd")
const Pieton = preload("res://scripts/pieton.gd")
const Victime = preload("res://scripts/victime.gd")
const Feu = preload("res://scripts/feu.gd")
const Hud = preload("res://scripts/hud.gd")
const Collegue = preload("res://scripts/collegue.gd")
const Son = preload("res://scripts/son.gd")

## Les trois scénarios du prototype. Les natures, poids et variantes viennent du référentiel.
const SCENARIOS: Dictionary = {
	"malaise_domicile": {"categorie": "secours_victime", "engin": "VSAV", "noeud": "d_maison",
		"adresse": "8, rue des Tanneurs", "victime_pos": Vector3(265, 0.05, -92.5)},
	"malaise_voie_publique": {"categorie": "secours_victime", "engin": "VSAV", "noeud": "d_chute",
		"adresse": "face au 140, boulevard des Acacias", "victime_pos": Vector3(163, 0.05, 11.5)},
	"feu_appartement": {"categorie": "incendie", "engin": "FPT", "noeud": "d_immeuble",
		"adresse": "21, rue des Remparts, 2e étage", "victime_pos": Vector3(-28.5, 6.15, -82.0)},
}

const APPELS: Dictionary = {
	"diabetique": ["F", 62, 86, "Sa fille : « Ma mère est diabétique, elle ne me répond plus normalement, elle est toute molle. »"],
	"cardiaque": ["M", 48, 74, "Le patient lui-même : « J'ai très mal dans la poitrine, ça serre, ça descend dans le bras. »"],
	"personne_agee_seule": ["F", 78, 93, "Une voisine : « Je l'entends appeler à l'aide, elle est tombée. J'ai la clé, je vous ouvre. »"],
	"ivresse": ["M", 22, 48, "Un passant : « Un homme est allongé par terre, il a l'air saoul, il ne se relève pas. »"],
	"epilepsie": ["M", 17, 38, "Une passante : « Un jeune a fait une crise, il a tremblé de partout, il ne répond pas ! »"],
	"chute_trottinette": ["M", 15, 34, "Un témoin : « Un garçon est tombé de sa trottinette, il a mal au bras et saigne de la tête. »"],
	"etage": ["F", 30, 80, "Un voisin : « De la fumée sort de l'appartement du 2e, ça sent le brûlé ! »"],
	"cage_escalier_enfumee": ["M", 30, 80, "Une habitante : « L'escalier est plein de fumée, on ne peut plus descendre ! »"],
	"victime_a_la_fenetre": ["F", 30, 80, "Un passant : « Quelqu'un appelle au secours à la fenêtre du 2e, il y a de la fumée ! »"],
}

const NOMS_VICTIMES: Array = ["Martin", "Bernard", "Dubois", "Durand", "Leroy", "Fournier", "Girardin", "Bonnet", "Lambertin", "Fontaine", "Chevalier", "Rousseau", "Blanc", "Garnier", "Faure"]

var ref: Dictionary = {}
var hud
var joueur
var vsav
var fpt
var engins: Array = []
var voitures: Array = []
var feu
var alarme
var env: Environment
var equipages: Dictionary = {}   # code engin -> liste de collègues
var chef_garde
var reserve                      # équipier VSAV qui reste à la caserne quand le joueur part
var interactions: Array = []
var etat := "caserne"
var statut := "disponible"
var mission: Dictionary = {}
var victime = null
var heure := 8.0 * 3600.0
var prochain_appel := 25.0
var tirage_realiste := false
var carriere: Dictionary = {"xp": 0, "interventions": 0, "notes": []}

## Réglages utilisés par le test automatique (tests/test_auto.gd).
var force_scenario := ""
var test_arrosage := false
var vitesse_test := 1.0

var _proche = null
var _assis = null   # engin dans lequel le joueur est assis (place passager)
var _t_alarme := 0.0
var _t_conseil := 0.0
var _t_alimentation := 0.0
var _alimentation := false
var _dans_batiment := false
var _drapeaux: Dictionary = {}   # messages déjà dits (pour ne pas répéter)


func _ready() -> void:
	randomize()
	_entrees()
	_environnement()
	Monde.construire(self)
	feu = Feu.new()
	add_child(feu)
	feu.preparer()
	joueur = Joueur.new()
	add_child(joueur)
	joueur.teleporter(Carte.DEPART_JOUEUR, PI)
	vsav = Engin.new()
	add_child(vsav)
	vsav.construire("VSAV")
	vsav.garer(Carte.PARKING_VSAV, PI)
	fpt = Engin.new()
	add_child(fpt)
	fpt.construire("FPT")
	fpt.garer(Carte.PARKING_FPT, PI)
	engins = [vsav, fpt]
	alarme = Son.new()
	alarme.mode = "alarme"
	alarme.position = Vector3(-250, 4, -40)
	add_child(alarme)
	var couleurs: Array = [Color(0.2, 0.3, 0.6), Color(0.6, 0.6, 0.62), Color(0.1, 0.1, 0.12), Color(0.55, 0.15, 0.15), Color(0.9, 0.9, 0.9), Color(0.3, 0.45, 0.3), Color(0.7, 0.6, 0.2), Color(0.35, 0.35, 0.4)]
	# Boulevard (axe est-ouest) puis rocade (axe nord-sud, voies plus larges).
	for i in 12:
		var v = Trafic.new()
		v.sens = 1.0 if i % 2 == 0 else -1.0
		v.monde = self
		add_child(v)
		v.construire(couleurs[i % couleurs.size()])
		v.placer(-390.0 + i * 85.0)
		voitures.append(v)
	for i in 10:
		var v = Trafic.new()
		v.sens = 1.0 if i % 2 == 0 else -1.0
		v.axe_z = true
		v.ligne = -420.0
		v.voie = 5.5
		v.bas_cote = 9.0
		v.a_min = -600.0
		v.a_max = 600.0
		v.vitesse_croisiere = 22.0
		v.ronds_points = [-300.0, 0.0, 240.0]
		v.monde = self
		add_child(v)
		v.construire(couleurs[(i + 3) % couleurs.size()])
		v.placer(-580.0 + i * 120.0)
		voitures.append(v)
	_creer_pietons()
	_creer_collegues()
	hud = Hud.new()
	add_child(hud)
	_charger_referentiel()
	_charger_carriere()
	_interactions_fixes()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.radio("Adjudant Girard (chef de garde)", "Bienvenue au centre de secours de Joué-lès-Tours. Tu es de garde comme équipier. Reste prêt, ça peut sonner à tout moment.", "#ffd27f")
	hud.radio("Conseil", "Promenez-vous dans la remise. Quand l'alarme sonne : vestiaire (E), puis montez dans l'engin indiqué sur le ticket.", "#b0ffb0")


# ---------------------------------------------------------------------------
# Préparation
# ---------------------------------------------------------------------------

func _action(nom: String, touches: Array) -> void:
	if InputMap.has_action(nom):
		return
	InputMap.add_action(nom)
	for k in touches:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(nom, ev)


## Les touches sont "physiques" : sur un clavier AZERTY, Z Q S D marchent comme W A S D.
func _entrees() -> void:
	_action("avancer", [KEY_W, KEY_UP])
	_action("reculer", [KEY_S, KEY_DOWN])
	_action("gauche", [KEY_A, KEY_LEFT])
	_action("droite", [KEY_D, KEY_RIGHT])
	_action("courir", [KEY_SHIFT])
	_action("interagir", [KEY_E])
	_action("accelerer", [KEY_T])
	_action("appel_suivant", [KEY_N])
	_action("tirage", [KEY_F2])
	_action("souris", [KEY_ESCAPE])
	_action("camera", [KEY_C])
	var chiffres: Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]
	for i in chiffres.size():
		_action("geste_%d" % (i + 1), [chiffres[i], KEY_KP_1 + i])


func _environnement() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var ciel := Sky.new()
	ciel.sky_material = _ciel_nuageux()
	ciel.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = ciel
	# Lumière ambiante : moitié ciel, moitié couleur neutre (sinon tout devient bleu).
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.35
	env.ambient_light_color = Color(0.8, 0.78, 0.74)
	env.ambient_light_energy = 0.6
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	# Ombres de contact et lumière qui rebondit entre les murs (le sol éclaire le bas des façades…).
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.0
	env.ssao_detail = 0.6
	env.ssil_enabled = true
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.5
	# Reflets sur les vitres, la carrosserie et le sol mouillé.
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.2
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	env.adjustment_contrast = 1.03
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.76, 0.82)
	env.fog_density = 0.0009
	env.fog_aerial_perspective = 0.3
	env.fog_sun_scatter = 0.05
	we.environment = env
	add_child(we)
	var soleil := DirectionalLight3D.new()
	# Soleil de fin d'après-midi : ombres plus longues, lumière un peu dorée.
	soleil.rotation_degrees = Vector3(-34, -38, 0)
	soleil.light_energy = 2.3
	soleil.light_color = Color(1.0, 0.93, 0.82)
	soleil.shadow_enabled = true
	soleil.shadow_blur = 1.0
	soleil.directional_shadow_max_distance = 260.0
	add_child(soleil)


## Ciel dégradé avec soleil et nuages (calculé par la carte graphique).
func _ciel_nuageux() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type sky;
uniform vec3 haut : source_color = vec3(0.16, 0.33, 0.66);
uniform vec3 horizon : source_color = vec3(0.62, 0.71, 0.83);
uniform vec3 sol : source_color = vec3(0.32, 0.33, 0.31);
uniform sampler2D bruit : filter_linear_mipmap, repeat_enable;
void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 c = mix(horizon, haut, pow(clamp(h, 0.0, 1.0), 0.45));
	if (h < 0.0) {
		c = mix(horizon, sol, clamp(-h * 5.0, 0.0, 1.0));
	}
	float s = 0.0;
	if (LIGHT0_ENABLED) {
		s = max(dot(d, LIGHT0_DIRECTION), 0.0);
		c += LIGHT0_COLOR * (pow(s, 6.0) * 0.12);
	}
	if (h > 0.0) {
		vec2 uv = d.xz / (h + 0.1) * 0.18;
		float n = texture(bruit, uv).r * 0.62 + texture(bruit, uv * 2.9 + vec2(0.31, 0.17)).r * 0.38;
		float couv = smoothstep(0.56, 0.8, n);
		float fondu = smoothstep(0.0, 0.2, h);
		vec3 ombre = vec3(0.62, 0.66, 0.72);
		vec3 clair = vec3(0.93, 0.92, 0.9);
		vec3 cn = mix(ombre, clair, smoothstep(0.55, 0.85, n) * 0.7 + pow(s, 4.0) * 0.3);
		c = mix(c, cn, couv * fondu * 0.92);
		if (LIGHT0_ENABLED) {
			// Disque du soleil (caché par les nuages épais)
			c += LIGHT0_COLOR * LIGHT0_ENERGY * smoothstep(0.9993, 0.9997, s) * 6.0 * (1.0 - couv);
		}
	}
	COLOR = c;
}
"""
	var n := FastNoiseLite.new()
	n.seed = 12
	n.frequency = 0.008
	n.fractal_octaves = 5
	var img: Image = n.get_seamless_image(512, 512)
	img.generate_mipmaps()
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("bruit", ImageTexture.create_from_image(img))
	return m


func _charger_referentiel() -> void:
	var txt := FileAccess.get_file_as_string("res://data/referentiel_pompiers.json")
	var data = JSON.parse_string(txt)
	if data is Dictionary:
		ref = data
	else:
		push_error("Référentiel introuvable ou illisible : data/referentiel_pompiers.json")


func _charger_carriere() -> void:
	if FileAccess.file_exists("user://carriere.json"):
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://carriere.json"))
		if data is Dictionary:
			carriere = data


func _sauver_carriere() -> void:
	var f := FileAccess.open("user://carriere.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(carriere, "  "))


func _nouveau_collegue(nom: String, grade: String, role: String, pos: Vector3, feu_tenue: bool):
	var c = Collegue.new()
	add_child(c)
	c.construire(nom, grade, role, feu_tenue)
	c.teleporter(pos)
	c.set_meta("pos_caserne", pos)
	return c


func _creer_collegues() -> void:
	var traits: Array = ["pedagogue", "rouspeteur"]
	var lambert = _nouveau_collegue("Lambert", "Caporal-chef", "chef d'agrès VSAV", Vector3(-240, 0, -60.5), false)
	lambert.trait_caractere = traits.pick_random()
	var diallo = _nouveau_collegue("Diallo", "Caporal", "conducteur VSAV", Vector3(-236, 0, -60.5), false)
	reserve = _nouveau_collegue("Lefèvre", "Sapeur 1re classe", "équipier VSAV", Vector3(-236, 0, -63.5), false)
	var moreau = _nouveau_collegue("Moreau", "Sergent", "chef d'agrès FPT", Vector3(-226, 0, -44), true)
	moreau.trait_caractere = traits.pick_random()
	var petit = _nouveau_collegue("Petit", "Caporal", "conducteur FPT", Vector3(-230, 0, -30), true)
	var nguyen = _nouveau_collegue("Nguyen", "Caporal", "chef d'équipe BAT (votre binôme)", Vector3(-229, 0, -46), true)
	var roux = _nouveau_collegue("Roux", "Sapeur 1re classe", "chef d'équipe BAL", Vector3(-224, 0, -50), true)
	var benali = _nouveau_collegue("Benali", "Sapeur", "équipier BAL", Vector3(-222, 0, -48), true)
	chef_garde = _nouveau_collegue("Girard", "Adjudant", "chef de garde", Vector3(-240, 0, -63.5), false)
	equipages["VSAV"] = [lambert, diallo]
	equipages["FPT"] = [moreau, petit, nguyen, roux, benali]


func _interactions_fixes() -> void:
	ajouter_interaction("vestiaire", Carte.VESTIAIRE + Vector3(0, 1, -5), 4.5, "S'habiller au vestiaire", _vestiaire)


# ---------------------------------------------------------------------------
# Interactions (touche E)
# ---------------------------------------------------------------------------

func ajouter_interaction(id: String, pos: Vector3, rayon: float, texte: String, action: Callable) -> void:
	retirer_interaction(id)
	interactions.append({"id": id, "pos": pos, "rayon": rayon, "texte": texte, "action": action})


func retirer_interaction(id: String) -> void:
	for i in range(interactions.size() - 1, -1, -1):
		if interactions[i]["id"] == id:
			interactions.remove_at(i)


func _chercher_interaction() -> void:
	_proche = null
	if not joueur.controle:
		return
	var p: Vector3 = joueur.global_position + Vector3(0, 1, 0)
	var meilleur := 9999.0
	for it in interactions:
		var d: float = p.distance_to(it["pos"])
		if d <= it["rayon"] and d < meilleur:
			meilleur = d
			_proche = it
	for it in _interactions_engins():
		var d2: float = p.distance_to(it["pos"])
		if d2 <= it["rayon"] and d2 < meilleur:
			meilleur = d2
			_proche = it


## Portes du VSAV : ouvrir/fermer, monter dans la cellule, s'asseoir, descendre.
func _interactions_engins() -> Array:
	var res: Array = []
	for e in engins:
		if e.portes.is_empty() or e.en_route:
			continue
		if e.global_position.distance_to(joueur.global_position) > 10.0:
			continue
		# Pendant un feu, les gestes de l'intervention (ARI, lance) passent avant les rideaux du FPT.
		if e.code == "FPT" and etat == "sur_place":
			continue
		var dedans: bool = e.dans_cellule(joueur.global_position + Vector3(0, 0.3, 0))
		for nom in e.portes:
			var pt: Dictionary = e.portes[nom]
			var verbe := "Fermer " if pt["ouvert"] else "Ouvrir "
			var pos_l: Vector3 = pt["point"]
			if dedans:
				# De l'intérieur, on attrape la porte par sa poignée intérieure
				pos_l = Vector3(clampf(pos_l.x, -0.7, 0.7), 1.2, clampf(pos_l.z, -0.6, 2.7))
			res.append({"id": "porte_" + nom, "pos": e.to_global(pos_l), "rayon": 1.2 if e.code == "FPT" else 1.4, "texte": verbe + str(pt["texte"]), "action": e.basculer_porte.bind(nom)})
		if e.code == "FPT":
			if e.porte_ouverte("avant_droite"):
				res.append({"id": "asseoir", "pos": e.to_global(Vector3(1.85, 1.0, -3.1)), "rayon": 0.9, "texte": "Monter à la place du chef d'agrès", "action": _s_asseoir.bind(e, 1)})
			for nom2 in ["equipage_droite", "equipage_gauche"]:
				if e.porte_ouverte(nom2):
					var cx: float = 1.85 if nom2 == "equipage_droite" else -1.85
					res.append({"id": "asseoir_equipage", "pos": e.to_global(Vector3(cx, 1.0, -2.0)), "rayon": 0.9, "texte": "Monter dans la cabine de l'équipage", "action": _s_asseoir.bind(e, 2)})
			continue
		var arriere: bool = e.porte_ouverte("arriere_gauche") or e.porte_ouverte("arriere_droite")
		if dedans:
			if arriere:
				res.append({"id": "descendre", "pos": e.to_global(Vector3(0, 1.75, 2.55)), "rayon": 1.0, "texte": "Descendre par l'arrière", "action": _descendre_cellule.bind(e, "arriere")})
			if e.porte_ouverte("laterale"):
				res.append({"id": "descendre_lat", "pos": e.to_global(Vector3(0.5, 1.75, -0.1)), "rayon": 1.0, "texte": "Descendre par la porte latérale", "action": _descendre_cellule.bind(e, "laterale")})
		else:
			if arriere:
				res.append({"id": "monter_ar", "pos": e.to_global(Vector3(0, 1.0, 3.75)), "rayon": 1.1, "texte": "Monter dans la cellule", "action": _monter_cellule.bind(e)})
			if e.porte_ouverte("laterale"):
				res.append({"id": "monter_lat", "pos": e.to_global(Vector3(1.75, 1.0, 0.1)), "rayon": 1.0, "texte": "Monter dans la cellule", "action": _monter_cellule.bind(e)})
			if e.porte_ouverte("avant_droite"):
				res.append({"id": "asseoir", "pos": e.to_global(Vector3(1.75, 1.0, -1.15)), "rayon": 0.9, "texte": "S'asseoir à la place passager", "action": _s_asseoir.bind(e, 1)})
	return res


func _monter_cellule(e) -> void:
	joueur.teleporter(e.to_global(Vector3(0.15, 0.78, 2.2)), e.rotation.y)


func _descendre_cellule(e, par: String) -> void:
	if par == "arriere":
		joueur.teleporter(e.to_global(Vector3(0, 0.05, 4.2)), e.rotation.y + PI)
	else:
		joueur.teleporter(e.to_global(Vector3(1.9, 0.05, 0.1)), e.rotation.y - PI * 0.5)


func _s_asseoir(e, place: int = 1) -> void:
	_assis = e
	joueur.activer(false)
	e.vue(place)
	var ou := "à la place passager"
	if e.code == "FPT":
		ou = "à la place du chef d'agrès" if place == 1 else "dans la cabine de l'équipage"
	hud.radio("Vous", "Installé %s. (E pour descendre)" % ou, "#dddddd")


func _se_lever() -> void:
	var e = _assis
	_assis = null
	joueur.teleporter(e.to_global(e.sortie_place()), e.rotation.y - PI * 0.5)
	joueur.activer(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("souris"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	var clic := event as InputEventMouseButton
	if clic != null and clic.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("camera"):
		var trajet := etat == "trajet" or etat == "transport" or etat == "retour"
		if trajet and mission.has("engin"):
			hud.set_invite(mission["engin"].changer_camera())
		return
	if event.is_action_pressed("interagir"):
		if _assis != null:
			_se_lever()
		elif etat == "fin" and hud.fin_visible():
			_reprendre_garde()
		elif _proche != null:
			var act: Callable = _proche["action"]
			act.call()
	elif event.is_action_pressed("appel_suivant"):
		if etat == "caserne":
			prochain_appel = 0.0
	elif event.is_action_pressed("tirage"):
		tirage_realiste = not tirage_realiste
		hud.radio("Réglage", "Tirage des appels : " + ("réaliste (proportions nationales 2024 : surtout du secours à victime)" if tirage_realiste else "équilibré (un tiers chaque scénario)"), "#b0ffb0")
	else:
		for i in range(1, 8):
			if event.is_action_pressed("geste_%d" % i):
				_geste(i)


# ---------------------------------------------------------------------------
# Boucle principale
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	# T maintenu : on accélère le temps pendant les trajets.
	var trajet := etat == "trajet" or etat == "transport" or etat == "retour"
	Engine.time_scale = (3.0 if (trajet and Input.is_action_pressed("accelerer")) else 1.0) * vitesse_test
	heure += delta
	_chercher_interaction()
	if _proche != null:
		hud.set_invite("[E] " + str(_proche["texte"]))
	elif etat == "fin":
		hud.set_invite("")
	else:
		hud.set_invite("")
	if _t_alarme > 0.0:
		_t_alarme -= delta
		if _t_alarme <= 0.0:
			alarme.actif = false
	match etat:
		"caserne":
			prochain_appel -= delta
			if prochain_appel <= 0.0:
				_declencher_appel()
		"depart", "trajet":
			_evoluer_scenario(delta, 0.5)
		"sur_place":
			_evoluer_scenario(delta, 1.0)
			_sur_place_process(delta)
	_maj_victime_hud()
	_maj_etat_hud()


func _maj_etat_hud() -> void:
	var h := int(heure / 3600.0) % 24
	var m := int(heure / 60.0) % 60
	var couleurs := {"disponible": "#7dff7d", "parti": "#ffb347", "sur_les_lieux": "#ff6b6b", "transport_hopital": "#c89bff", "arrive_hopital": "#c89bff", "retour": "#9fd3ff", "indisponible": "#aaaaaa"}
	var t := "[b]Garde — %02d:%02d[/b]   Statut : [color=%s]%s[/color]\n" % [h, m, couleurs.get(statut, "#ffffff"), statut.replace("_", " ")]
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		t += "Secteur : [color=#ffe08a]%s[/color]\n" % Carte.quartier_a(cam.global_position)
	t += "Sapeur 2e classe — XP %d — %d intervention(s)\n" % [int(carriere.get("xp", 0)), int(carriere.get("interventions", 0))]
	var tenue_txt := "tenue de service"
	if joueur.tenue == "suap":
		tenue_txt = "tenue d'intervention"
	elif joueur.tenue == "feu":
		tenue_txt = "tenue de feu"
	t += "Tenue : " + tenue_txt
	if joueur.ari:
		var c := "#ffffff" if joueur.air > 55.0 else "#ff5555"
		t += " · ARI [color=%s]%d bar[/color]" % [c, int(joueur.air)]
	if joueur.lance:
		t += " · Lance en main · Eau : " + ("alimentée par le PI" if _alimentation else "%d L" % int(fpt.eau))
	if joueur.sante < 100.0:
		t += "\nÉtat physique : %d %%" % int(joueur.sante)
	if etat == "caserne":
		t += "\nTirage : " + ("réaliste" if tirage_realiste else "équilibré") + " (F2)"
	hud.set_etat(t)


func _set_statut(s: String, engin_code: String) -> void:
	statut = s
	var libelle := {"parti": "parti", "sur_les_lieux": "sur les lieux", "transport_hopital": "transport vers le centre hospitalier", "arrive_hopital": "arrivé au centre hospitalier", "retour": "retour au centre", "disponible": "disponible au centre"}
	hud.radio(engin_code + " Joué", "Statut : " + str(libelle.get(s, s)) + ".", "#ffb347")


# ---------------------------------------------------------------------------
# Tirage d'un appel (à partir du référentiel)
# ---------------------------------------------------------------------------

func _sous_type(categorie: String, id: String) -> Dictionary:
	for c in ref.get("categories", []):
		if c["id"] == categorie:
			for s in c["sous_types"]:
				if s["id"] == id:
					var res: Dictionary = s
					res["_part_categorie"] = c["part"]
					res["_nom_categorie"] = c["nom"]
					return res
	return {"id": id, "nom": id, "variantes": ["etage"], "depart_reflexe": {}, "poids": 1.0, "_part_categorie": 1.0, "_nom_categorie": categorie, "modulateurs": {}}


func _est_nuit() -> bool:
	var h := int(heure / 3600.0) % 24
	return h >= 22 or h < 6


func _tirer_scenario() -> String:
	var ids: Array = SCENARIOS.keys()
	if force_scenario != "":
		return force_scenario
	if not tirage_realiste:
		return ids.pick_random()
	# Poids = part de la catégorie x poids du sous-type x modulateur de nuit.
	var poids: Array = []
	var total := 0.0
	for id in ids:
		var st := _sous_type(SCENARIOS[id]["categorie"], id)
		var w: float = float(st["_part_categorie"]) * float(st["poids"])
		if _est_nuit():
			w *= float(st.get("modulateurs", {}).get("nuit", 1.0))
		poids.append(w)
		total += w
	var r := randf() * total
	for i in ids.size():
		r -= poids[i]
		if r <= 0.0:
			return ids[i]
	return ids[0]


func _delai_reference() -> float:
	for c in ref.get("sdis_fictif", {}).get("casernes", []):
		if c["id"] == "joue_les_tours":
			var d: Dictionary = c["delai_depart_min"]
			return float(d["nuit"] if _est_nuit() else d["jour"]) * 60.0
	return 180.0


func _declencher_appel() -> void:
	var id := _tirer_scenario()
	var sc: Dictionary = SCENARIOS[id]
	var st := _sous_type(sc["categorie"], id)
	var variantes: Array = st.get("variantes", [])
	var variante: String = variantes.pick_random() if variantes.size() > 0 else ""
	var appel: Array = APPELS.get(variante, ["M", 30, 60, "Appel au 18."])
	mission = {
		"id": id, "sc": sc, "st": st, "variante": variante, "debut": heure,
		"penalites": [], "bons_points": [], "engin": vsav if sc["engin"] == "VSAV" else fpt,
		"victime_sauvee": false, "pieces_brulees": {},
	}
	_drapeaux.clear()
	_alimentation = false
	_t_alimentation = 0.0
	fpt.eau = fpt.eau_max
	joueur.air = 300.0
	joueur.sante = 100.0
	# Victime
	victime = Victime.new()
	add_child(victime)
	var sexe: String = appel[0]
	victime.construire(NOMS_VICTIMES.pick_random(), randi_range(int(appel[1]), int(appel[2])), sexe)
	victime.global_position = sc["victime_pos"]
	victime.rotation.y = randf() * TAU
	if id == "feu_appartement":
		victime.configurer("intox_fumees")
		var piece_depart: String = ["Cuisine", "Séjour"].pick_random()
		feu.reinitialiser()
		feu.allumer(piece_depart, 35.0)
		mission["pieces_brulees"][piece_depart] = true
		if variante == "cage_escalier_enfumee":
			feu.enfumer("Palier", 70.0)
			feu.enfumer("Entrée", 60.0)
		# Une fois sur deux, l'appartement est vide (sauf si quelqu'un appelle à la fenêtre).
		if variante == "etage" and randf() < 0.5:
			victime.queue_free()
			victime = null
	else:
		victime.configurer(variante)
	# Ticket de départ
	var dr: Dictionary = st.get("depart_reflexe", {})
	var dr_txt: Array = []
	for k in dr.keys():
		dr_txt.append("%s ×%d" % [k, int(dr[k])])
	var engages := "VSAV Joué (vous : équipier)"
	if id == "feu_appartement":
		engages = "FPT Joué (vous : équipier BAT, binôme d'attaque), VSAV Joué.\nLes autres engins du départ réflexe (2e FPT, EPA, VLCG) viennent de Tours-Centre : ils sont seulement simulés à la radio dans ce prototype."
	var hh := int(heure / 3600.0) % 24
	var mm := int(heure / 60.0) % 60
	var t := "[b][color=#ff6b6b]DÉPART[/color][/b] — %s — %02d:%02d\n" % [ref.get("sdis_fictif", {}).get("cta_codis", {}).get("nom", "CTA-CODIS"), hh, mm]
	t += "[b]Nature[/b] : %s (%s)\n" % [st["nom"], st["_nom_categorie"]]
	t += "[b]Adresse[/b] : %s, Joué-lès-Tours\n" % sc["adresse"]
	t += "[b]Renseignements[/b] : %s\n" % appel[3]
	t += "[b]Départ réflexe (référentiel)[/b] : %s\n" % ", ".join(PackedStringArray(dr_txt))
	t += "[b]Engagés[/b] : %s\n" % engages
	t += "[color=#b0ffb0]→ Vestiaire (E), puis montez dans le %s.[/color]" % sc["engin"]
	hud.afficher_ticket(t)
	alarme.actif = true
	_t_alarme = 7.0
	hud.radio("CTA-CODIS", "Départ pour le centre de Joué : %s, %s." % [st["nom"].to_lower(), sc["adresse"]], "#ff9f9f")
	etat = "depart"
	# Les collègues courent vers les engins.
	for e in _engins_engages():
		var eq: Array = _equipage(e)
		for i in eq.size():
			eq[i].aller(e.global_position + Vector3((i - 1) * 1.3, 0, -6.0))
	ajouter_interaction("monter", mission["engin"].global_position + Vector3(0, 1.5, 0), 6.0, "Monter dans le " + sc["engin"], _monter_depart)


func _engins_engages() -> Array:
	if mission.get("id", "") == "feu_appartement":
		return [fpt, vsav]
	return [vsav]


func _equipage(e) -> Array:
	var eq: Array = equipages[e.code].duplicate()
	if e == vsav and mission.get("id", "") == "feu_appartement":
		eq.append(reserve)
	return eq


func _chef(e = null):
	if e == null:
		e = mission.get("engin", vsav)
	return equipages[e.code][0]


## Le chef d'agrès parle. Son trait de caractère change le ton.
func _chef_dit(texte: String, e = null) -> void:
	var c = _chef(e)
	hud.radio(c.nom_complet() + " (chef d'agrès)", texte, "#ffd27f")


func _faute(points: int, texte: String, remarque: String = "") -> void:
	mission["penalites"].append([points, texte])
	var c = _chef()
	c.confiance = maxf(0.0, c.confiance - points * 3.0)
	if remarque != "":
		if c.trait_caractere == "rouspeteur":
			_chef_dit("Non mais sérieux ?! " + remarque)
		else:
			_chef_dit(remarque + " Ce n'est pas grave, retiens-le pour la prochaine fois.")


func _bien(texte: String) -> void:
	mission["bons_points"].append(texte)
	var c = _chef()
	c.confiance = minf(100.0, c.confiance + 6.0)


# ---------------------------------------------------------------------------
# Caserne : habillage et départ
# ---------------------------------------------------------------------------

func _vestiaire() -> void:
	if etat != "depart":
		hud.radio("Vous", "Vous rangez votre casier. Tenue de service.", "#dddddd")
		joueur.tenue = ""
		return
	var voulu := "feu" if mission["sc"]["engin"] == "FPT" else "suap"
	joueur.tenue = voulu
	if voulu == "feu":
		hud.radio("Vous", "Tenue de feu enfilée : veste, surpantalon, bottes, cagoule, casque et gants.", "#dddddd")
	else:
		hud.radio("Vous", "Tenue d'intervention enfilée, gants à usage unique dans la poche.", "#dddddd")


func _monter_depart() -> void:
	var e = mission["engin"]
	if joueur.tenue == "":
		_chef_dit("Tu ne montes pas en tenue de service ! File au vestiaire.")
		return
	if e == fpt and joueur.tenue != "feu":
		_chef_dit("Pour le FPT, c'est la tenue de feu. Retourne au vestiaire.")
		return
	retirer_interaction("monter")
	hud.cacher_ticket()
	var delai: float = heure - float(mission["debut"])
	var ref_delai := _delai_reference()
	mission["delai_depart"] = delai
	if delai <= ref_delai * 0.5:
		_bien("Départ rapide (%d s)" % int(delai))
	elif delai > ref_delai:
		_faute(2, "Départ trop lent (%d s, objectif %d s)" % [int(delai), int(ref_delai)])
	_partir_vers_lieux()


func _partir_vers_lieux() -> void:
	etat = "trajet"
	joueur.activer(false)
	var noeud: String = mission["sc"]["noeud"]
	var e = mission["engin"]
	_assis = null
	e.vue(0)
	_set_statut("parti", e.code)
	var engages := _engins_engages()
	for i in engages.size():
		var eng = engages[i]
		for c in _equipage(eng):
			c.visible = false
		var pts: Array = [Vector3(eng.global_position.x, 0, -12)]
		var recul := 0.0 if i == 0 else 16.0
		var garage := 6.5 if noeud == "d_chute" else 4.0
		pts.append_array(Carte.chemin_points("caserne", noeud, 3.0, garage, recul))
		if i == 0:
			eng.partir(pts, true)
		else:
			# Le deuxième engin part quelques secondes plus tard.
			get_tree().create_timer(4.0).timeout.connect(func(): eng.partir(pts, true))
		_connecter(eng, "lieux")
	hud.radio("Conducteur", "Deux-tons, gyrophares, c'est parti. (Maintenez T pour accélérer le trajet.)", "#ffd27f")


# ---------------------------------------------------------------------------
# Arrivées des engins
# ---------------------------------------------------------------------------

## Branche l'arrivée d'un engin sur la suite du scénario (une seule à la fois).
func _connecter(e, but: String) -> void:
	for c in e.arrive.get_connections():
		e.arrive.disconnect(c["callable"])
	e.arrive.connect(_engin_arrive.bind(e, but), CONNECT_ONE_SHOT)


func _engin_arrive(e, but: String) -> void:
	match but:
		"lieux":
			e.set_sirene(false)
			_deployer_equipage(e)
			if e == mission.get("engin") and etat == "trajet":
				_sur_place()
		"hopital":
			_a_l_hopital()
		"caserne":
			for cx in e.arrive.get_connections():
				e.arrive.disconnect(cx["callable"])
			e.garer(Carte.PARKING_VSAV if e == vsav else Carte.PARKING_FPT, PI)
			for c in _equipage(e):
				c.visible = true
				c.arreter()
				c.teleporter(c.get_meta("pos_caserne"))
				c.set_casque(e == fpt)
			if e == mission.get("engin") and etat == "retour":
				_rentre()


func _deployer_equipage(e) -> void:
	var eq: Array = _equipage(e)
	for i in eq.size():
		var c = eq[i]
		c.visible = true
		c.teleporter(e.global_position + e.droite() * 2.2 + e.avant() * (i - 1.5) * 1.4)


func _sur_place() -> void:
	etat = "sur_place"
	var e = mission["engin"]
	_set_statut("sur_les_lieux", e.code)
	joueur.teleporter(e.global_position + e.droite() * (e.largeur * 0.5 + 1.3), e.rotation.y)
	joueur.activer(true)
	_t_conseil = 0.0
	var id: String = mission["id"]
	if id == "feu_appartement":
		_sur_place_feu()
		return
	var chef = _chef()
	chef.aller(victime.global_position + Vector3(1.2, 0, 1.0))
	var cond = equipages["VSAV"][1]
	cond.aller(e.global_position - e.avant() * (e.longueur * 0.5 + 1.0))
	if victime.agitee:
		_chef_dit("Attention, la victime a l'air agitée. On reste calme, on se présente et on parle doucement.")
	if chef.trait_caractere == "pedagogue":
		_chef_dit("Prends le sac de secours. Commence par le bilan (touche 1), puis fais les gestes adaptés. Je te regarde faire.")
	else:
		_chef_dit("Allez, on se bouge : sac, bilan, gestes. Et pas de bêtise.")
	ajouter_interaction("victime", victime.global_position + Vector3(0, 1, 0), 3.0, "Parler à la victime", _parler_victime)


func _parler_victime() -> void:
	if victime == null:
		return
	if victime.conscience == "inconscient":
		hud.radio("Vous", "« Madame ? Monsieur ? Vous m'entendez ? » Pas de réponse.", "#dddddd")
		return
	if victime.agitee:
		if randf() < 0.6:
			victime.agitee = false
			hud.radio(victime.civilite(), "« ...D'accord, d'accord. Faites ce que vous avez à faire. »", "#ffb0b0")
			_bien("Victime agitée calmée par le dialogue")
		else:
			hud.radio(victime.civilite(), "« Me touchez pas ! »", "#ffb0b0")
		return
	hud.radio(victime.civilite(), "« " + victime.plainte + " »", "#ffb0b0")


func _geste(i: int) -> void:
	if etat != "sur_place" or victime == null or mission.get("id") == "feu_appartement":
		return
	if victime.prise_en_charge:
		return
	var d: float = joueur.global_position.distance_to(victime.global_position)
	if d > 3.0:
		hud.set_invite("Approchez-vous de la victime pour faire un geste.")
		return
	var g: String = Victime.GESTES[i - 1]
	var res: Dictionary = victime.geste(g)
	hud.radio("Vous", str(res["message"]), "#dddddd")
	if int(res["penalite"]) > 0:
		_faute(int(res["penalite"]), str(res["faute"]), str(res["faute"]) + ".")
	if not res["ok"]:
		return
	_t_conseil = 0.0
	if g == "transmettre":
		hud.radio("Médecin régulateur (SAMU 37)", "Bien reçu. Vous transportez aux urgences du centre hospitalier. Rappelez si aggravation.", "#c89bff")
		_bien("Bilan transmis au médecin régulateur")
	if g == "brancard":
		_chef_dit("On part sur le centre hospitalier. Monte à l'arrière avec la victime.")
		retirer_interaction("victime")
		var e = mission["engin"]
		# On charge par l'arrière : portes ouvertes, victime installée sur le brancard de la cellule
		e.ouvrir_porte("arriere_gauche")
		e.ouvrir_porte("arriere_droite")
		e.victime_a_bord(true)
		ajouter_interaction("transport", e.global_position + Vector3(0, 1.5, 0), 6.0, "Monter dans le VSAV (transport)", _partir_hopital)


## Le chef d'agrès donne des conseils si le joueur est bloqué. L'IA tient compte de son caractère.
func _sur_place_process(delta: float) -> void:
	_t_conseil += delta
	if mission["id"] == "feu_appartement":
		_feu_process(delta)
		return
	if victime == null or victime.prise_en_charge:
		return
	if _t_conseil > 25.0:
		_t_conseil = 0.0
		var manquants: Array = victime.gestes_manquants()
		var c = _chef()
		var conseil := ""
		if not victime.bilan_fait:
			conseil = "Fais le bilan (1), on ne sait toujours rien de ses constantes."
		elif manquants.size() > 0 and manquants[0] != "transmettre":
			conseil = "Il manque : %s." % Victime.NOMS_GESTES[manquants[0]].to_lower()
		elif not victime.bilan_transmis:
			conseil = "Transmets le bilan au médecin régulateur (6)."
		else:
			conseil = "On brancarde et on charge (7)."
		if c.trait_caractere == "rouspeteur":
			_chef_dit("Bon, on va y passer la journée ? " + conseil)
			c.confiance = maxf(0.0, c.confiance - 2.0)
		else:
			_chef_dit("Un conseil : " + conseil)


func _partir_hopital() -> void:
	retirer_interaction("transport")
	etat = "transport"
	var e = mission["engin"]
	joueur.activer(false)
	e.vue(2)   # on voyage à l'arrière, avec la victime
	_set_statut("transport_hopital", e.code)
	for c in _equipage(e):
		c.visible = false
	var urgent: bool = victime.etat < 40.0
	e.partir(Carte.chemin_points(mission["sc"]["noeud"], "H", 3.0, 6.0), urgent)
	_connecter(e, "hopital")


func _a_l_hopital() -> void:
	var e = mission["engin"]
	_set_statut("arrive_hopital", e.code)
	e.victime_a_bord(false)
	hud.radio("Infirmière d'accueil", "On la prend en salle 3. Merci les pompiers.", "#c89bff")
	_rentrer_au_centre(e, "H")


func _rentrer_au_centre(e, depuis: String) -> void:
	etat = "retour"
	_set_statut("retour", e.code)
	var pts: Array = Carte.chemin_points(depuis, "caserne", 3.0, 3.0)
	var x: float = (Carte.PARKING_VSAV if e == vsav else Carte.PARKING_FPT).x
	pts.append(Vector3(x, 0, -12))
	pts.append(Vector3(x, 0, -34))
	e.partir(pts, false)
	_connecter(e, "caserne")


func _rentre() -> void:
	var e = mission["engin"]
	_set_statut("disponible", e.code)
	joueur.teleporter(e.global_position + Vector3(e.largeur * 0.5 + 1.5, 0.2, 0), PI)
	joueur.activer(true)
	joueur.ari = false
	joueur.lance = false
	joueur.porte_victime = false
	_fin_intervention()


# ---------------------------------------------------------------------------
# Feu d'appartement
# ---------------------------------------------------------------------------

func _sur_place_feu() -> void:
	var chef = _chef()
	var pieces: Array = feu.pieces_en_feu()
	var ambiance := "Fumées noires au 2e étage, feu visible dans : %s." % ", ".join(PackedStringArray(pieces))
	if mission["variante"] == "victime_a_la_fenetre" and victime != null:
		ambiance += " Une personne appelle à la fenêtre !"
	hud.radio(chef.nom_complet() + " → CODIS", "Message d'ambiance : " + ambiance + " J'engage un binôme en reconnaissance et attaque.", "#ffd27f")
	_chef_dit("Binôme d'attaque : capelez les ARI, prenez une lance et montez au 2e par l'escalier. Reconnaissance, sauvetage, puis extinction.")
	var nguyen = equipages["FPT"][2]
	nguyen.suivre(joueur)
	var roux = equipages["FPT"][3]
	var benali = equipages["FPT"][4]
	roux.aller(Carte.POTEAU_INCENDIE + Vector3(1, 0, 0))
	benali.aller(Carte.POTEAU_INCENDIE + Vector3(1, 0, 1.2))
	chef.aller(Carte.PORTE_IMMEUBLE + Vector3(-3, 0, 3))
	_t_alimentation = 0.0
	var arriere: Vector3 = fpt.global_position - fpt.avant() * (fpt.longueur * 0.5 + 0.8)
	ajouter_interaction("ari", arriere + Vector3(0, 1, 0), 3.0, "Capeler l'ARI (appareil respiratoire)", _capeler)
	ajouter_interaction("lance", fpt.global_position + fpt.droite() * 1.8 + Vector3(0, 1, 0), 3.5, "Prendre la lance (établissement)", _prendre_lance)
	ajouter_interaction("porte", Carte.PORTE_IMMEUBLE + Vector3(-0.5, 1, 0), 2.5, "Monter au 2e étage par l'escalier", _monter_escalier)
	ajouter_interaction("palier", Carte.PALIER_2E + Vector3(0, 0.7, 0), 2.0, "Redescendre dans la rue", _descendre_escalier)
	if victime != null:
		ajouter_interaction("victime", victime.global_position + Vector3(0, 0.8, 0), 1.8, "Sauver la victime (la porter)", _porter_victime)


func _capeler() -> void:
	if joueur.ari:
		hud.radio("Vous", "ARI déjà capelé.", "#dddddd")
		return
	joueur.ari = true
	fpt.ouvrir_porte("coffre_droit_0")   # les ARI sont rangés dans le coffre avant droit
	joueur.air = 300.0
	hud.radio("Vous", "ARI capelé, contrôle de la pression : 300 bars. Masque prêt.", "#dddddd")
	hud.radio("Caporal Nguyen", "Contrôle d'engagement fait auprès du chef. On y va quand tu as la lance.", "#ffe9a8")


func _prendre_lance() -> void:
	joueur.lance = true
	fpt.ouvrir_porte("coffre_droit_1")   # tuyaux et lances : coffre du milieu
	hud.radio("Vous", "Lance prise, l'établissement suit jusqu'au 2e étage. Clic gauche pour arroser.", "#dddddd")


func _monter_escalier() -> void:
	if not joueur.lance:
		_chef_dit("Tu montes sans lance ? Prends l'établissement d'abord.")
		return
	if not joueur.ari:
		_faute(6, "Engagement en zone enfumée sans ARI", "Tu t'engages sans ARI dans un immeuble enfumé ! C'est une faute grave.")
	_fondu()
	joueur.teleporter(Carte.PALIER_2E, 0.0)
	var nguyen = equipages["FPT"][2]
	nguyen.teleporter(Carte.PALIER_2E + Vector3(1.0, -0.2, 1.0))
	nguyen.suivre(joueur)
	hud.radio("Vous", "Arrivée au palier du 2e. Porte de l'appartement : on écoute, on regarde la fumée, on entre.", "#dddddd")


func _descendre_escalier() -> void:
	_fondu()
	joueur.teleporter(Carte.PORTE_IMMEUBLE + Vector3(-3.0, 0.2, 0), PI * 0.5)
	var nguyen = equipages["FPT"][2]
	nguyen.teleporter(Carte.PORTE_IMMEUBLE + Vector3(-3.0, 0, 1.5))
	if joueur.porte_victime and victime != null:
		joueur.porte_victime = false
		victime.visible = true
		victime.dans_fumee = false
		victime.global_position = vsav.global_position + vsav.droite() * 2.5
		mission["victime_sauvee"] = true
		_bien("Victime sauvée")
		hud.radio("Caporal-chef Lambert (VSAV)", "On prend la victime en charge : %s, %s, SpO2 %d %%. Oxygène et bilan au médecin." % [victime.civilite(), victime.texte_conscience(), int(victime.spo2)], "#ffd27f")


func _porter_victime() -> void:
	if victime == null:
		return
	joueur.porte_victime = true
	victime.visible = false
	retirer_interaction("victime")
	hud.radio("Vous", "Victime chargée sur l'épaule avec l'aide du binôme. Direction le palier !", "#dddddd")


func _fondu() -> void:
	var tw := create_tween()
	tw.tween_method(hud.set_voile, 1.0, 0.0, 0.7)


func _feu_process(delta: float) -> void:
	var p: Vector3 = joueur.global_position + Vector3(0, 1.0, 0)
	_dans_batiment = joueur.global_position.y > 4.0
	# Alimentation en eau par le binôme BAL sur le poteau d'incendie.
	_t_alimentation += delta
	if not _alimentation and _t_alimentation > 80.0:
		_alimentation = true
		hud.radio("Sapeur 1re classe Roux (BAL)", "Alimentation établie sur le poteau d'incendie !", "#ffe9a8")
	# Air de l'ARI
	if joueur.ari and _dans_batiment:
		joueur.air = maxf(0.0, joueur.air - 1.9 * delta)
		if joueur.air < 55.0 and not _drapeaux.has("sifflet"):
			_drapeaux["sifflet"] = true
			hud.radio("ARI", "*Sifflet de fin de charge* — il reste moins de 55 bars, il faut ressortir !", "#ff5555")
		if joueur.air <= 0.0:
			_faute(5, "Bouteille d'ARI vide en zone enfumée", "Tu as vidé ta bouteille ! On surveille sa pression, toujours.")
			_evacuer()
			joueur.air = 300.0
	# Fumée et chaleur
	var fumee: float = feu.fumee_a(p)
	var chaleur: float = feu.chaleur_a(p)
	if _dans_batiment and fumee > 25.0 and not joueur.ari:
		joueur.sante -= fumee * 0.12 * delta
	if chaleur > 60.0:
		joueur.sante -= 4.0 * delta
		if not _drapeaux.has("chaud"):
			_drapeaux["chaud"] = true
			hud.radio("Caporal Nguyen", "Trop chaud, on recule ! On attaque depuis la porte.", "#ffe9a8")
	if joueur.sante <= 0.0:
		_faute(6, "Blessé en intervention : évacué par le binôme", "Ton binôme a dû te sortir. On ne s'engage pas n'importe comment.")
		_evacuer()
		joueur.sante = 60.0
	var fum_vue: float = fumee if _dans_batiment else 0.0
	env.fog_density = lerpf(env.fog_density, 0.0009 + fum_vue / 100.0 * 0.22, minf(1.0, delta * 3.0))
	env.fog_light_color = Color(0.72, 0.76, 0.82).lerp(Color(0.12, 0.11, 0.1), clampf(fum_vue / 60.0, 0.0, 1.0))
	if victime != null and not mission["victime_sauvee"]:
		victime.dans_fumee = not joueur.porte_victime
	# Lance
	var arrose: bool = joueur.lance and joueur.controle and ((Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) or test_arrosage)
	var eau_ok: bool = _alimentation or fpt.eau > 0.0
	joueur.jet.emitting = arrose and eau_ok
	if arrose and eau_ok:
		if not _alimentation:
			fpt.eau = maxf(0.0, fpt.eau - 8.3 * delta)
			if fpt.eau <= 0.0:
				hud.radio("Caporal Petit (conducteur)", "Citerne vide ! On attend l'alimentation du PI.", "#ffe9a8")
		var o: Vector3 = joueur.camera.global_position
		var dir: Vector3 = joueur.direction_regard()
		var q := PhysicsRayQueryParameters3D.create(o, o + dir * 14.0)
		q.exclude = [joueur.get_rid()]
		var r := get_world_3d().direct_space_state.intersect_ray(q)
		var portee := 14.0
		if not r.is_empty():
			portee = o.distance_to(r["position"]) + 0.6
		var touchee: String = feu.arroser(o, dir, portee, delta)
		if touchee != "" and not _drapeaux.has("attaque"):
			_drapeaux["attaque"] = true
			hud.radio("Caporal Nguyen", "C'est bien, petites impulsions, on refroidit les fumées puis on vise la base des flammes.", "#ffe9a8")
	for nom in feu.pieces_en_feu():
		mission["pieces_brulees"][nom] = true
	# Feu éteint ?
	if feu.eteint() and not _drapeaux.has("eteint"):
		_drapeaux["eteint"] = true
		hud.radio(_chef().nom_complet() + " → CODIS", "Feu éteint. Fin de reconnaissance : %s. Je garde le FPT pour le déblai, le reste des moyens peut rentrer." % ("une victime sauvée" if mission["victime_sauvee"] else ("aucune victime" if victime == null else "victime toujours dans l'appartement !")), "#ffd27f")
	if _drapeaux.has("eteint") and (victime == null or mission["victime_sauvee"]) and not _drapeaux.has("fin_ok"):
		_drapeaux["fin_ok"] = true
		_chef_dit("Bon travail. On reconditionne et on rentre : redescends et monte dans le FPT.")
		ajouter_interaction("rentrer", fpt.global_position + Vector3(0, 1.5, 0), 6.0, "Monter dans le FPT (retour)", _retour_feu)
	# Conseils de l'IA
	if _t_conseil > 30.0 and not _drapeaux.has("eteint"):
		_t_conseil = 0.0
		if not joueur.ari:
			_chef_dit("Capelle ton ARI à l'arrière du FPT.")
		elif not joueur.lance:
			_chef_dit("Prends la lance sur le côté du FPT.")
		elif not _dans_batiment:
			_chef_dit("Monte au 2e par l'entrée de l'immeuble.")
		elif victime != null and not mission["victime_sauvee"] and not joueur.porte_victime:
			hud.radio("Caporal Nguyen", "On fouille toutes les pièces, il peut y avoir quelqu'un. La chambre est au fond.", "#ffe9a8")
		else:
			hud.radio("Caporal Nguyen", "Le feu est dans : %s. On avance pièce par pièce." % ", ".join(PackedStringArray(feu.pieces_en_feu())), "#ffe9a8")


func _evacuer() -> void:
	if _dans_batiment:
		joueur.porte_victime = false
		if victime != null and not mission["victime_sauvee"]:
			victime.visible = true
		_descendre_escalier()


func _retour_feu() -> void:
	if _dans_batiment:
		return
	retirer_interaction("rentrer")
	for id in ["ari", "lance", "porte", "palier", "victime"]:
		retirer_interaction(id)
	env.fog_density = 0.0009
	env.fog_light_color = Color(0.72, 0.76, 0.82)
	joueur.ari = false
	joueur.lance = false
	joueur.jet.emitting = false
	joueur.activer(false)
	fpt.camera.current = true
	for c in _equipage(fpt):
		c.visible = false
		c.arreter()
	for c in _equipage(vsav):
		c.visible = false
	if victime != null:
		victime.visible = false
		victime.prise_en_charge = true
	# Le VSAV transporte la victime au centre hospitalier : pour simplifier, on le remet directement au centre.
	_engin_arrive(vsav, "caserne")
	_rentrer_au_centre(fpt, "d_immeuble")


# ---------------------------------------------------------------------------
# Évolution, affichage de la victime, note de fin
# ---------------------------------------------------------------------------

func _evoluer_scenario(delta: float, facteur: float) -> void:
	if victime != null:
		victime.evoluer(delta * facteur)
	if mission.get("id", "") == "feu_appartement":
		feu.evoluer(delta * facteur)


func _maj_victime_hud() -> void:
	if etat != "sur_place":
		hud.set_victime("")
		return
	if mission["id"] == "feu_appartement":
		var t := "[b]Feu d'appartement[/b]\n"
		if _dans_batiment:
			var p: Vector3 = joueur.global_position + Vector3(0, 1, 0)
			var piece: String = feu.nom_piece_a(p)
			t += "Pièce : %s · fumée %s\n" % [piece if piece != "" else "?", _niveau(feu.fumee_a(p))]
		var en_feu: Array = feu.pieces_en_feu()
		t += "Pièces en feu (vues par le binôme) : %s\n" % (", ".join(PackedStringArray(en_feu)) if en_feu.size() > 0 else "aucune")
		if victime != null:
			if mission["victime_sauvee"]:
				t += "Victime : sauvée, prise en charge par le VSAV"
			elif joueur.porte_victime:
				t += "Victime : sur votre épaule, ressortez par le palier !"
			else:
				t += "Victime signalée : à rechercher"
		t += "\n[color=#aaaaaa]E : ARI à l'arrière du FPT · lance sur le côté · entrée de l'immeuble · clic gauche : arroser[/color]"
		hud.set_victime(t)
		return
	if victime == null or victime.prise_en_charge:
		hud.set_victime("")
		return
	var t2 := "[b]Victime[/b] : %s, %d ans\n[i]%s[/i]\n" % [victime.civilite(), victime.age, victime.plainte]
	if victime.bilan_fait:
		t2 += "[b]Constantes[/b] :\n" + victime.texte_constantes() + "\n"
	else:
		t2 += "[b]Constantes[/b] : faites le bilan pour les connaître.\n"
	t2 += "[b]Gestes[/b] (à moins de 3 m) :\n"
	for i in Victime.GESTES.size():
		var g: String = Victime.GESTES[i]
		var fait := "[color=#7dff7d]✓[/color] " if victime.faits.has(g) else ""
		t2 += "%d · %s%s\n" % [i + 1, fait, Victime.NOMS_GESTES[g]]
	t2 += "[color=#aaaaaa]E près de la victime : lui parler[/color]"
	hud.set_victime(t2)


func _niveau(v: float) -> String:
	if v < 10.0:
		return "nulle"
	if v < 35.0:
		return "légère"
	if v < 65.0:
		return "épaisse"
	return "opaque"


func _fin_intervention() -> void:
	etat = "fin"
	var note := 20.0
	var lignes: Array = []
	for p in mission["penalites"]:
		note -= float(p[0])
		lignes.append("[color=#ff8080]−%d[/color] %s" % [int(p[0]), p[1]])
	if victime != null:
		if mission["id"] != "feu_appartement":
			for g in victime.gestes_manquants():
				note -= 2.0
				lignes.append("[color=#ff8080]−2[/color] Geste oublié : %s" % Victime.NOMS_GESTES[g].to_lower())
		elif not mission["victime_sauvee"]:
			note -= 8.0
			lignes.append("[color=#ff8080]−8[/color] Victime non retrouvée")
		var grav: String = victime.gravite_finale()
		if grav == "décédée":
			note -= 8.0
			lignes.append("[color=#ff8080]−8[/color] Victime décédée")
		elif grav == "urgence absolue":
			note -= 3.0
			lignes.append("[color=#ff8080]−3[/color] Victime aggravée (urgence absolue)")
	if mission["id"] == "feu_appartement":
		var brulees: Array = mission["pieces_brulees"].keys()
		if brulees.size() > 1:
			note -= float(brulees.size() - 1)
			lignes.append("[color=#ff8080]−%d[/color] Le feu s'est propagé (%s)" % [brulees.size() - 1, ", ".join(PackedStringArray(brulees))])
	note = clampf(round(note), 0.0, 20.0)
	var xp := 20 + int(note) * 5
	carriere["xp"] = int(carriere.get("xp", 0)) + xp
	carriere["interventions"] = int(carriere.get("interventions", 0)) + 1
	var notes: Array = carriere.get("notes", [])
	notes.append(int(note))
	carriere["notes"] = notes
	_sauver_carriere()
	var chef = _chef()
	var avis := ""
	if chef.confiance >= 65.0:
		avis = "« Du bon boulot. Je repartirai avec toi sans problème. »"
	elif chef.confiance >= 40.0:
		avis = "« Correct. Il y a des choses à revoir, on en reparle au débriefing. »"
	else:
		avis = "« Il va falloir te reprendre. On fera une manœuvre demain matin. »"
	var duree: float = heure - float(mission["debut"])
	var t := "[b]FIN D'INTERVENTION — %s[/b]\n" % mission["st"]["nom"]
	t += "Variante tirée : %s · durée : %d min %02d s\n" % [str(mission["variante"]).replace("_", " "), int(duree / 60.0), int(duree) % 60]
	if mission.has("delai_depart"):
		t += "Délai de départ : %d s (référence du centre : %d s)\n" % [int(mission["delai_depart"]), int(_delai_reference())]
	if victime != null:
		t += "Victime : %s, %s\n" % [victime.civilite(), victime.gravite_finale()]
	t += "\n[b]Note : %d / 20[/b]   (+%d XP)\n" % [int(note), xp]
	for b in mission["bons_points"]:
		t += "[color=#7dff7d]✓[/color] %s\n" % b
	for l in lignes:
		t += l + "\n"
	t += "\n[b]Avis du chef d'agrès[/b] (%s) : %s\n" % [chef.nom_complet(), avis]
	var xp_total := int(carriere["xp"])
	if xp_total >= 500:
		t += "\nCarrière : Sapeur 2e classe · %d XP. Seuil atteint pour Sapeur 1re classe : la formation et la promotion arrivent dans une prochaine version.\n" % xp_total
	else:
		t += "\nCarrière : Sapeur 2e classe · %d XP / 500 pour pouvoir passer Sapeur 1re classe.\n" % xp_total
	t += "\n[color=#b0ffb0]Appuyez sur E pour reprendre la garde.[/color]"
	hud.afficher_fin(t)


func _reprendre_garde() -> void:
	hud.cacher_fin()
	etat = "caserne"
	statut = "disponible"
	if victime != null:
		victime.queue_free()
		victime = null
	feu.reinitialiser()
	for id in ["victime", "transport", "ari", "lance", "porte", "palier", "rentrer", "monter"]:
		retirer_interaction(id)
	joueur.tenue = ""
	joueur.sante = 100.0
	for code in equipages.keys():
		for c in equipages[code]:
			c.visible = true
			c.arreter()
			c.teleporter(c.get_meta("pos_caserne"))
	reserve.visible = true
	reserve.teleporter(reserve.get_meta("pos_caserne"))
	mission = {}
	prochain_appel = randf_range(30.0, 60.0)
	hud.radio("Adjudant Girard (chef de garde)", "Engins reconditionnés. Prochain départ quand ça sonnera.", "#ffd27f")


## Des passants sur les trottoirs du centre et du lotissement.
func _creer_pietons() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 18
	var segments: Array = [
		[Vector3(-195, 0, -11.2), Vector3(-55, 0, -11.2)], [Vector3(-45, 0, -11.2), Vector3(95, 0, -11.2)],
		[Vector3(105, 0, -11.2), Vector3(245, 0, -11.2)], [Vector3(255, 0, -11.2), Vector3(318, 0, -11.2)],
		[Vector3(-318, 0, 11.2), Vector3(-205, 0, 11.2)], [Vector3(-195, 0, 11.2), Vector3(-55, 0, 11.2)],
		[Vector3(-45, 0, 11.2), Vector3(95, 0, 11.2)], [Vector3(105, 0, 11.2), Vector3(135, 0, 11.2)],
		[Vector3(185, 0, 11.2), Vector3(245, 0, 11.2)],
		[Vector3(-192.8, 0, -140), Vector3(-192.8, 0, -16)], [Vector3(-57.2, 0, 16), Vector3(-57.2, 0, 110)],
		[Vector3(107.2, 0, -140), Vector3(107.2, 0, -16)], [Vector3(92.8, 0, 16), Vector3(92.8, 0, 110)],
		[Vector3(242.8, 0, -140), Vector3(242.8, 0, -16)],
		[Vector3(-35, 0, -229.3), Vector3(240, 0, -229.3)], [Vector3(260, 0, -360.7), Vector3(440, 0, -360.7)],
	]
	for seg in segments:
		var nb := 2 + rng.randi() % 3
		for k in nb:
			var p = Pieton.new()
			p.depart = seg[0]
			p.arrivee = seg[1]
			p.monde = self
			add_child(p)
			p.construire(rng)

