## Une victime avec un modèle physiologique simplifié.
## Le joueur ne voit pas de barre de vie : il doit faire un bilan pour lire les constantes.
## Quatre fonctions suivies : conscience, ventilation (FR, SpO2), circulation (pouls, TA), température.
extends Node3D

const Geo = preload("res://scripts/geo.gd")
const Corps = preload("res://scripts/corps.gd")

const GESTES: Array = ["bilan", "oxygene", "pls", "immobilisation", "couverture", "transmettre", "brancard"]
const NOMS_GESTES: Dictionary = {
	"bilan": "Faire le bilan (constantes)",
	"oxygene": "Oxygène (inhalation)",
	"pls": "Position latérale de sécurité",
	"immobilisation": "Immobilisation (attelle, collier)",
	"couverture": "Couverture de survie",
	"transmettre": "Transmettre le bilan au médecin",
	"brancard": "Brancarder et charger au VSAV",
}

var nom := ""
var age := 50
var sexe := "M"
var variante := ""
var plainte := ""
var conscience := "conscient"    # conscient, somnolent, inconscient
var agitee := false
var fr := 16.0
var spo2 := 98.0
var pouls := 80.0
var tas := 130.0
var temp := 37.0
var glycemie := 1.0
var etat := 100.0                # 0 = décédé, 100 = stable (caché au joueur)

var requis: Array = []           # gestes attendus
var interdits: Array = []        # gestes dangereux pour cette victime
var faits: Array = []
var bilan_fait := false
var bilan_transmis := false
var prise_en_charge := false     # chargée dans le VSAV
var dans_fumee := false
var _corps: Node3D
var corps: Node3D   # le corps articulé (corps.gd), allongé
var _etiquette: Label3D


func construire(p_nom: String, p_age: int, p_sexe: String) -> void:
	nom = p_nom
	age = p_age
	sexe = p_sexe
	_corps = Node3D.new()
	add_child(_corps)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	corps = Corps.new()
	_corps.add_child(corps)
	corps.construire(Corps.tenue_civile(rng, sexe, age))
	corps.allonger(true)
	_etiquette = Geo.texte(self, "Victime", Vector3(0, 1.2, 0), 32, Color(1, 0.6, 0.6))


func civilite() -> String:
	return ("Mme " if sexe == "F" else "M. ") + nom


## Règle l'état de départ selon la variante tirée au sort (données du référentiel).
func configurer(p_variante: String) -> void:
	variante = p_variante
	match variante:
		"diabetique":
			plainte = "Diabétique sous insuline, retrouvée somnolente et confuse par sa fille."
			conscience = "inconscient"
			fr = 14; spo2 = 95; pouls = 98; tas = 125; temp = 36.6; glycemie = 0.42
			requis = ["bilan", "pls", "transmettre"]
			interdits = []
		"cardiaque":
			plainte = "Douleur dans la poitrine qui serre, irradie dans le bras gauche, depuis 30 minutes."
			conscience = "conscient"
			fr = 24; spo2 = 91; pouls = 112; tas = 158; temp = 36.9; glycemie = 1.1
			requis = ["bilan", "oxygene", "transmettre"]
			interdits = ["pls"]
		"personne_agee_seule":
			plainte = "Au sol depuis la nuit, ne peut pas se relever, douleur à la hanche droite."
			conscience = "conscient"
			fr = 18; spo2 = 96; pouls = 88; tas = 110; temp = 35.1; glycemie = 0.95
			requis = ["bilan", "couverture", "immobilisation", "transmettre"]
			interdits = ["pls"]
		"ivresse":
			plainte = "Allongé sur le trottoir, sent l'alcool, agressif, refuse d'abord les soins."
			conscience = "somnolent"
			agitee = true
			fr = 16; spo2 = 97; pouls = 92; tas = 120; temp = 35.6; glycemie = 0.9
			requis = ["bilan", "couverture", "transmettre"]
			interdits = []
		"epilepsie":
			plainte = "Crise convulsive devant témoins il y a 5 minutes, ne répond pas encore."
			conscience = "inconscient"
			fr = 20; spo2 = 93; pouls = 104; tas = 135; temp = 37.2; glycemie = 1.0
			requis = ["bilan", "pls", "transmettre"]
			interdits = ["immobilisation"]
		"chute_trottinette":
			plainte = "Chute de trottinette, douleur et déformation de l'avant-bras, a heurté la tête."
			conscience = "conscient"
			fr = 20; spo2 = 98; pouls = 100; tas = 140; temp = 36.8; glycemie = 1.0
			requis = ["bilan", "immobilisation", "transmettre"]
			interdits = ["pls"]
		"intox_fumees":
			plainte = "Retrouvée dans la chambre enfumée, tousse, très confuse."
			conscience = "somnolent"
			fr = 28; spo2 = 88; pouls = 120; tas = 100; temp = 37.0; glycemie = 1.0
			etat = 75.0
			requis = []
		_:
			plainte = "Malaise."
	_appliquer_posture()


func _appliquer_posture() -> void:
	if _corps == null:
		return
	if faits.has("pls"):
		_corps.rotation.z = PI * 0.5
		_corps.position.y = 0.15
	else:
		_corps.rotation.z = 0.0
		_corps.position.y = 0.0


func texte_conscience() -> String:
	match conscience:
		"inconscient":
			return "inconsciente, respire" if sexe == "F" else "inconscient, respire"
		"somnolent":
			return "somnolente, confuse" if sexe == "F" else "somnolent, confus"
	return "consciente, orientée" if sexe == "F" else "conscient, orienté"


func texte_constantes() -> String:
	return "Conscience : %s\nFR %d/min · SpO2 %d %% · Pouls %d/min\nTA %d mmHg (systolique) · T° %.1f °C · Glycémie %.2f g/L" % [
		texte_conscience(), int(fr), int(spo2), int(pouls), int(tas), temp, glycemie]


func texte_bilan_radio() -> String:
	var gestes_txt: Array = []
	for g in faits:
		if g != "bilan" and g != "transmettre":
			gestes_txt.append(NOMS_GESTES[g].to_lower())
	var liste := "aucun"
	if gestes_txt.size() > 0:
		liste = ", ".join(PackedStringArray(gestes_txt))
	return "%s, %d ans. %s Victime %s. FR %d, SpO2 %d %%, pouls %d, TA %d, température %.1f, glycémie %.2f. Gestes : %s." % [
		civilite(), age, plainte, texte_conscience(), int(fr), int(spo2), int(pouls), int(tas), temp, glycemie, liste]


## Applique un geste. Renvoie {ok, message, penalite, faute}.
func geste(g: String) -> Dictionary:
	var res := {"ok": true, "message": "", "penalite": 0, "faute": ""}
	if prise_en_charge:
		res.ok = false
		res.message = "La victime est déjà dans le VSAV."
		return res
	if faits.has(g) and g != "bilan":
		res.ok = false
		res.message = "C'est déjà fait."
		return res
	if agitee and g != "bilan" and g != "transmettre" and randf() < 0.4:
		res.ok = false
		res.message = "La victime vous repousse : « Laissez-moi tranquille ! ». Parlez-lui calmement et réessayez."
		agitee = randf() < 0.6
		return res
	match g:
		"bilan":
			bilan_fait = true
			res.message = "Bilan : " + texte_constantes().replace("\n", " · ")
		"oxygene":
			res.message = "Masque à haute concentration posé, 9 L/min."
			if spo2 >= 95:
				res.message += " (La saturation était déjà correcte.)"
				res.penalite = 1
				res.faute = "Oxygène sans indication (SpO2 normale)"
		"pls":
			res.message = "Victime mise en position latérale de sécurité."
			if conscience == "conscient":
				res.penalite = 3
				res.faute = "PLS sur une victime consciente"
		"immobilisation":
			res.message = "Membre immobilisé, collier cervical posé."
		"couverture":
			res.message = "Couverture de survie posée, victime protégée du froid."
		"transmettre":
			if not bilan_fait:
				res.ok = false
				res.message = "Le chef d'agrès : « Fais d'abord le bilan avant d'appeler le médecin ! »"
				return res
			bilan_transmis = true
			res.message = "Bilan transmis au médecin régulateur du SAMU 37. Réponse : transport aux urgences du centre hospitalier."
		"brancard":
			if not bilan_transmis:
				res.ok = false
				res.message = "Le chef d'agrès : « On attend la décision du médecin régulateur avant de charger. »"
				return res
			prise_en_charge = true
			visible = false
			res.message = "Victime installée sur le brancard et chargée dans le VSAV."
	if g in interdits:
		res.penalite = int(res.penalite) + 3
		if res.faute == "":
			res.faute = "Geste contre-indiqué : " + NOMS_GESTES[g]
	if not bilan_fait and g != "bilan" and g != "transmettre" and g != "brancard":
		res.penalite = int(res.penalite) + 1
		if res.faute == "":
			res.faute = "Geste fait avant le bilan"
	if not faits.has(g):
		faits.append(g)
	_appliquer_posture()
	return res


func gestes_manquants() -> Array:
	var m: Array = []
	for g in requis:
		if not faits.has(g):
			m.append(g)
	return m


## Évolution dans le temps : sans les bons gestes, l'état se dégrade.
func evoluer(delta: float) -> void:
	if etat <= 0.0:
		return
	var perte := 0.0
	if variante == "intox_fumees":
		if dans_fumee:
			perte += 0.45
			spo2 = maxf(60.0, spo2 - delta * 0.15)
		else:
			spo2 = minf(95.0, spo2 + delta * 0.2)
	else:
		if not prise_en_charge:
			for g in gestes_manquants():
				if g == "pls" or g == "oxygene":
					perte += 0.12
				elif g == "couverture":
					perte += 0.05
				elif g == "immobilisation":
					perte += 0.04
	if faits.has("pls") and spo2 < 97.0:
		spo2 += delta * 0.08
	if faits.has("oxygene") and spo2 < 98.0:
		spo2 += delta * 0.25
		pouls = maxf(85.0, pouls - delta * 0.1)
	if not faits.has("pls") and requis.has("pls"):
		spo2 = maxf(80.0, spo2 - delta * 0.05)
	if requis.has("couverture"):
		if faits.has("couverture"):
			temp = minf(36.5, temp + delta * 0.004)
		else:
			temp = maxf(33.5, temp - delta * 0.002)
	etat = clampf(etat - perte * delta, 0.0, 100.0)
	if etat < 30.0 and conscience == "conscient":
		conscience = "somnolent"
	if etat < 15.0:
		conscience = "inconscient"


func gravite_finale() -> String:
	if etat <= 0.0:
		return "décédée"
	if etat < 40.0:
		return "urgence absolue"
	return "urgence relative"


func _process(delta: float) -> void:
	if corps != null and visible:
		corps.animer(0.0, delta)
