## Test automatique : joue les trois scénarios sans intervention humaine
## et affiche la note de fin. Lancement (pour les développeurs) :
##   godot --headless --path . res://tests/test_auto.tscn
extends Node

var main
var resultats: Array = []


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.vitesse_test = 8.0
	await get_tree().create_timer(1.0).timeout
	await _test_portes_vsav()
	await _test_fpt()
	for id in ["malaise_domicile", "malaise_voie_publique", "feu_appartement"]:
		for essai in 2:
			await _jouer(id)
	print("=== RÉSUMÉ ===")
	for r in resultats:
		print(r)
	get_tree().quit()


## Ouvre les portes arrière par l'interaction, monte dans la cellule, ressort, referme.
func _test_portes_vsav() -> void:
	var v = main.vsav
	main.joueur.teleporter(v.to_global(Vector3(0, 0.05, v.VsavModele.Z_AR + 0.95)), v.rotation.y + PI)
	await get_tree().create_timer(0.2).timeout
	for nom in ["arriere_gauche", "arriere_droite"]:
		v.basculer_porte(nom)
	await get_tree().create_timer(1.5).timeout
	var monter: Array = main._interactions_engins().filter(func(i): return i["id"] == "monter_ar")
	if monter.is_empty():
		resultats.append("portes VSAV : ÉCHEC (pas de proposition pour monter)")
		return
	monter[0]["action"].call()
	await get_tree().create_timer(0.5).timeout
	var dedans: bool = v.dans_cellule(main.joueur.global_position + Vector3(0, 0.3, 0))
	var descendre: Array = main._interactions_engins().filter(func(i): return i["id"] == "descendre")
	if not dedans or descendre.is_empty():
		resultats.append("portes VSAV : ÉCHEC (joueur pas dans la cellule)")
		return
	descendre[0]["action"].call()
	v.fermer_portes()
	await get_tree().create_timer(1.5).timeout
	main.joueur.teleporter(Vector3(-250, 0.2, -22), 0.0)
	resultats.append("portes VSAV : OK (monté et descendu)")


## FPT : ouvre un rideau de coffre et la porte de l'équipage, monte en cabine, redescend.
func _test_fpt() -> void:
	var f = main.fpt
	main.joueur.teleporter(f.to_global(Vector3(2.0, 0.05, 1.4)), f.rotation.y)
	await get_tree().create_timer(0.2).timeout
	var coffre: Array = main._interactions_engins().filter(func(i): return i["id"] == "porte_coffre_droit_1")
	if coffre.is_empty():
		resultats.append("FPT : ÉCHEC (pas de rideau à ouvrir)")
		return
	coffre[0]["action"].call()
	await get_tree().create_timer(1.2).timeout
	if not f.porte_ouverte("coffre_droit_1"):
		resultats.append("FPT : ÉCHEC (le rideau ne s'ouvre pas)")
		return
	main.joueur.teleporter(f.to_global(Vector3(2.0, 0.05, -2.0)), f.rotation.y)
	await get_tree().create_timer(0.2).timeout
	var porte: Array = main._interactions_engins().filter(func(i): return i["id"] == "porte_equipage_droite")
	if porte.is_empty():
		resultats.append("FPT : ÉCHEC (pas de porte d'équipage)")
		return
	porte[0]["action"].call()
	await get_tree().create_timer(1.2).timeout
	var monter: Array = main._interactions_engins().filter(func(i): return i["id"] == "asseoir_equipage")
	if monter.is_empty():
		resultats.append("FPT : ÉCHEC (pas de proposition pour monter en cabine)")
		return
	monter[0]["action"].call()
	await get_tree().create_timer(0.3).timeout
	if main._assis != f:
		resultats.append("FPT : ÉCHEC (pas assis dans la cabine)")
		return
	main._se_lever()
	f.fermer_portes()
	await get_tree().create_timer(1.2).timeout
	main.joueur.teleporter(Vector3(-250, 0.2, -22), 0.0)
	resultats.append("FPT : OK (rideau ouvert, monté en cabine et descendu)")


func _attendre_etat(e: String, max_s: float) -> bool:
	var t := 0.0
	while main.etat != e and t < max_s:
		await get_tree().process_frame
		t += get_process_delta_time()
	return main.etat == e


func _jouer(id: String) -> void:
	main.force_scenario = id
	main.prochain_appel = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	print("--- Appel : ", id, " / variante ", main.mission.get("variante"))
	main._vestiaire()
	main._monter_depart()
	if not await _attendre_etat("sur_place", 400.0):
		print("ÉCHEC : jamais arrivé sur place (", main.etat, ")")
		resultats.append(id + " : ÉCHEC arrivée")
		return
	print("Sur place. Engin en ", main.mission["engin"].global_position)
	if id == "feu_appartement":
		await _feu()
	else:
		await _sap()
		if not await _attendre_etat("hopital", 400.0):
			print("ÉCHEC : jamais arrivé aux urgences (", main.etat, ")")
			resultats.append(id + " : ÉCHEC urgences")
			return
		main.joueur.teleporter(main.infirmiere.global_position + Vector3(0, 0.2, -1.2), 0.0)
		await get_tree().process_frame
		await get_tree().process_frame
		if main._proche == null or main._proche["id"] != "iao":
			print("ÉCHEC : pas de proposition de transmission à l'IAO (", main._proche, ")")
		main._transmettre_iao()
		main._remonter_hopital()
	if not await _attendre_etat("reconditionnement", 600.0):
		print("ÉCHEC : jamais rentré (", main.etat, ")")
		resultats.append(id + " : ÉCHEC retour")
		return
	var deroule: String = main.hud._deroule.text
	if deroule.contains("oublié"):
		print("Déroulé avec étapes oubliées :\n", deroule)
		resultats.append(id + " : ÉCHEC déroulé (étape oubliée)")
	main._reconditionner()
	if not await _attendre_etat("fin", 600.0):
		print("ÉCHEC : pas de fin (", main.etat, ")")
		resultats.append(id + " : ÉCHEC fin")
		return
	var texte: String = main.hud._fin.text
	print(texte)
	resultats.append(id + " (" + str(main.mission["variante"]) + ") : " + texte.get_slice("Note : ", 1).get_slice("/", 0) + "/20")
	main._reprendre_garde()
	await get_tree().process_frame


func _sap() -> void:
	var v = main.victime
	# Sans le sac, le chef refuse les gestes.
	main.joueur.teleporter(v.global_position + Vector3(1.0, 0.2, 0.0), 0.0)
	await get_tree().process_frame
	main._geste(1)
	if v.bilan_fait:
		print("ÉCHEC : bilan possible sans le sac")
	main.mission["penalites"].clear()
	main._prendre_sac()
	main._ecouter_temoin()
	if not main.mission["temoin"]:
		print("ÉCHEC : pas de témoin")
	main._parler_victime()
	main._geste(1)
	var correspondance := {"oxygene": 2, "pls": 3, "immobilisation": 4, "couverture": 5}
	for g in v.requis:
		if correspondance.has(g):
			for essai in 5:   # une victime agitée peut refuser
				main._geste(correspondance[g])
				if v.faits.has(g):
					break
	main._geste(6)
	for essai in 5:   # une victime agitée peut refuser le brancard
		main._geste(7)
		if v.faits.has("brancard"):
			break
	print("Victime : ", v.texte_constantes().replace("\n", " | "), " — gestes faits ", v.faits)
	if main.interactions.filter(func(i): return i["id"] == "transport").size() == 0:
		print("ÉCHEC : pas de proposition de transport")
		return
	main._partir_hopital()


func _feu() -> void:
	main._capeler()
	main._prendre_lance()
	main._monter_escalier()
	await get_tree().process_frame
	main.joueur.teleporter(Vector3(-32, 6.3, -106), PI)
	main.test_arrosage = true
	var t := 0.0
	var z := -106.0
	while not main.feu.eteint() and t < 120.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		# On avance doucement dans l'appartement en arrosant.
		z = minf(z + get_process_delta_time() * 0.6, -83.0)
		main.joueur.teleporter(Vector3(-32, 6.3, z), PI)
	print("Feu éteint : ", main.feu.eteint(), " après ", int(t), " s (temps réel), air ", int(main.joueur.air))
	main.test_arrosage = false
	if main.victime != null:
		main.joueur.teleporter(main.victime.global_position + Vector3(0.5, 0.2, 0), 0.0)
		main._porter_victime()
	main._descendre_escalier()
	await get_tree().create_timer(0.5).timeout
	main.joueur.teleporter(main.fpt.global_position + Vector3(3, 0.2, 0), 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var ok := false
	for it in main.interactions:
		if it["id"] == "rentrer":
			ok = true
	print("Proposition de retour : ", ok)
	main._retour_feu()
