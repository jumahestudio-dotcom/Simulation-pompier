## Plan du quartier : les carrefours (noeuds) et les rues qui les relient.
## Unités : mètres. x vers l'est, z vers le sud.
extends RefCounted

const NOEUDS: Dictionary = {
	# Centre ancien (boulevard des Acacias et rues perpendiculaires)
	"caserne": Vector3(-250, 0, 0),
	"B1": Vector3(-200, 0, 0), "B2": Vector3(-50, 0, 0), "B3": Vector3(100, 0, 0), "B4": Vector3(250, 0, 0),
	"N1": Vector3(-200, 0, -150), "N2": Vector3(-50, 0, -150), "N3": Vector3(100, 0, -150), "N4": Vector3(250, 0, -150),
	"S1": Vector3(-200, 0, 120), "S2": Vector3(-50, 0, 120), "S3": Vector3(100, 0, 120), "S4": Vector3(250, 0, 120),
	# Rive sud du Cher
	"P": Vector3(100, 0, 240), "H": Vector3(180, 0, 240),
	"Q1": Vector3(-150, 0, 240), "Q3": Vector3(350, 0, 240), "Q5": Vector3(620, 0, 240),
	"Q1s": Vector3(-150, 0, 400), "Ps": Vector3(100, 0, 400), "Q3s": Vector3(350, 0, 400),
	# Rocade et rond-point
	"W": Vector3(-420, 0, 0), "Rn": Vector3(-420, 0, -300), "Rs": Vector3(-420, 0, 240),
	"Rnn": Vector3(-420, 0, -620), "Rss": Vector3(-420, 0, 620),
	# Zone d'activités (est)
	"E1": Vector3(450, 0, 0), "E2": Vector3(650, 0, 0), "N5": Vector3(450, 0, -150), "E1s": Vector3(450, 0, 120),
	# Nord : grands ensembles et pavillons
	"M1": Vector3(-200, 0, -300), "M2": Vector3(-50, 0, -300), "M4": Vector3(250, 0, -300), "M5": Vector3(450, 0, -300), "M6": Vector3(620, 0, -300),
	"T1": Vector3(-200, 0, -430), "T2": Vector3(-50, 0, -430), "T4": Vector3(250, 0, -430), "T5": Vector3(450, 0, -430), "T6": Vector3(620, 0, -430),
	"V3": Vector3(350, 0, -150), "V3n": Vector3(350, 0, -430), "V6": Vector3(620, 0, -150),
	# Destinations des interventions
	"d_maison": Vector3(250, 0, -90),
	"d_chute": Vector3(160, 0, 0),
	"d_immeuble": Vector3(-50, 0, -95),
}

const ARETES: Array = [
	["caserne", "B1"], ["B1", "B2"], ["B2", "B3"], ["B3", "d_chute"], ["d_chute", "B4"],
	["B1", "N1"], ["B2", "d_immeuble"], ["d_immeuble", "N2"], ["B3", "N3"], ["B4", "d_maison"], ["d_maison", "N4"],
	["N1", "N2"], ["N2", "N3"], ["N3", "N4"],
	["B1", "S1"], ["B2", "S2"], ["B3", "S3"], ["B4", "S4"], ["S1", "S2"], ["S2", "S3"], ["S3", "S4"],
	["S3", "P"], ["P", "H"],
	# Rive sud
	["Q1", "P"], ["H", "Q3"], ["Q3", "Q5"], ["Q1", "Q1s"], ["P", "Ps"], ["Q3", "Q3s"], ["Q1s", "Ps"], ["Ps", "Q3s"], ["Rs", "Q1"],
	# Rocade
	["caserne", "W"], ["W", "Rn"], ["W", "Rs"], ["Rn", "Rnn"], ["Rs", "Rss"],
	# Est
	["B4", "E1"], ["E1", "E2"], ["E1", "N5"], ["N4", "V3"], ["V3", "N5"], ["N5", "V6"], ["E1", "E1s"], ["S4", "E1s"],
	# Nord
	["N1", "M1"], ["N2", "M2"], ["N4", "M4"], ["N5", "M5"], ["Rn", "M1"], ["M1", "M2"], ["M2", "M4"], ["M4", "M5"], ["M5", "M6"], ["V6", "M6"],
	["M1", "T1"], ["M2", "T2"], ["M4", "T4"], ["M5", "T5"], ["M6", "T6"], ["T1", "T2"], ["T2", "T4"], ["T4", "V3n"], ["V3n", "T5"], ["T5", "T6"],
	["V3", "V3n"],
]

## Largeur des chaussées : boulevard 16 m, rocade 22 m, autres rues 10 m.
static func largeur_arete(a: String, b: String) -> float:
	var pa: Vector3 = NOEUDS[a]
	var pb: Vector3 = NOEUDS[b]
	if absf(pa.x + 420.0) < 1.0 and absf(pb.x + 420.0) < 1.0:
		return 22.0
	if absf(pa.z) < 1.0 and absf(pb.z) < 1.0:
		return 16.0
	return 10.0


## Les quartiers de la ville (pour l'affichage du nom et la génération).
const QUARTIERS: Array = [
	["Centre ancien", Rect2(-330, -160, 660, 320)],
	["Les Tilleuls (grands ensembles)", Rect2(-330, -450, 290, 290)],
	["Les Vignes (pavillons)", Rect2(-40, -450, 680, 290)],
	["Zone d'activités des Ormeaux", Rect2(330, -160, 340, 320)],
	["Bords du Cher", Rect2(-700, 155, 1600, 65)],
	["Rive sud", Rect2(-410, 220, 1080, 250)],
	["Rocade", Rect2(-445, -650, 50, 1300)],
	["Campagne", Rect2(-900, -650, 455, 1300)],
]


static func quartier_a(pos: Vector3) -> String:
	for q in QUARTIERS:
		var r: Rect2 = q[1]
		if r.has_point(Vector2(pos.x, pos.z)):
			return q[0]
	return "Joué-lès-Tours"


## Noms de rues (fictifs).
const NOM_BOULEVARD := "boulevard des Acacias"
const NOM_RUE_EST := "rue des Tanneurs"
const NOM_RUE_OUEST := "rue des Remparts"

## Positions importantes.
const PARKING_VSAV := Vector3(-262, 0, -38)
const PARKING_FPT := Vector3(-238, 0, -38)
const VESTIAIRE := Vector3(-276, 0, -62)
const DEPART_JOUEUR := Vector3(-250, 0.2, -55)
const PORTE_IMMEUBLE := Vector3(-42, 0, -95)
const PALIER_2E := Vector3(-36, 6.3, -107)
const POTEAU_INCENDIE := Vector3(-44, 0, -72)


## Plus court chemin entre deux noeuds (algorithme de Dijkstra).
static func chemin_noeuds(depart: String, arrivee: String) -> Array:
	var voisins: Dictionary = {}
	for n in NOEUDS.keys():
		voisins[n] = []
	for a in ARETES:
		voisins[a[0]].append(a[1])
		voisins[a[1]].append(a[0])
	var dist: Dictionary = {}
	var prec: Dictionary = {}
	var restants: Array = NOEUDS.keys()
	for n in restants:
		dist[n] = INF
	dist[depart] = 0.0
	while restants.size() > 0:
		var meilleur: String = restants[0]
		for n in restants:
			if dist[n] < dist[meilleur]:
				meilleur = n
		restants.erase(meilleur)
		if meilleur == arrivee:
			break
		for v in voisins[meilleur]:
			var p1: Vector3 = NOEUDS[meilleur]
			var p2: Vector3 = NOEUDS[v]
			var d: float = dist[meilleur] + p1.distance_to(p2)
			if d < dist[v]:
				dist[v] = d
				prec[v] = meilleur
	var res: Array = [arrivee]
	var cur: String = arrivee
	while prec.has(cur):
		cur = prec[cur]
		res.push_front(cur)
	return res


## Transforme une suite de noeuds en points à suivre, sur la voie de droite.
## "recul" : l'engin se gare quelques mètres avant le point d'arrivée.
static func chemin_points(depart: String, arrivee: String, voie: float = 3.0, garage: float = 6.0, recul: float = 0.0) -> Array:
	var noeuds: Array = chemin_noeuds(depart, arrivee)
	var pts: Array = []
	var d_der := Vector3.FORWARD
	for i in range(noeuds.size() - 1):
		var a: Vector3 = NOEUDS[noeuds[i]]
		var b: Vector3 = NOEUDS[noeuds[i + 1]]
		var d: Vector3 = (b - a).normalized()
		var r: Vector3 = d.cross(Vector3.UP)
		var marge: float = minf(7.0, a.distance_to(b) * 0.3)
		pts.append(a + r * voie + d * marge)
		pts.append(b + r * voie - d * marge)
		d_der = d
	if recul > 0.0 and pts.size() > 0:
		pts.pop_back()
	var fin: Vector3 = NOEUDS[arrivee]
	var r_der: Vector3 = d_der.cross(Vector3.UP)
	pts.append(fin + r_der * garage - d_der * recul)
	return pts
