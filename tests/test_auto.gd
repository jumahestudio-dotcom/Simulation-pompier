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
	for id in ["malaise_domicile", "malaise_voie_publique", "feu_appartement"]:
		for essai in 2:
			await _jouer(id)
	print("=== RÉSUMÉ ===")
	for r in resultats:
		print(r)
	get_tree().quit()


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
	main.joueur.teleporter(v.global_position + Vector3(1.0, 0.2, 0.0), 0.0)
	await get_tree().process_frame
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
	main._geste(7)
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
