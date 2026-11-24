## L'interface à l'écran : état, ticket de départ, radio, aide aux gestes, note de fin.
extends CanvasLayer

var _etat: RichTextLabel
var _ticket_boite: PanelContainer
var _ticket: RichTextLabel
var _radio: RichTextLabel
var _invite: Label
var _victime_boite: PanelContainer
var _victime: RichTextLabel
var _fin_boite: PanelContainer
var _fin: RichTextLabel
var _deroule_boite: PanelContainer
var _deroule: RichTextLabel
var _aide: Label
var _viseur: Label
var _voile: ColorRect
var _lignes_radio: Array = []


func _ready() -> void:
	var racine := Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(racine)

	_voile = ColorRect.new()
	_voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_voile.color = Color(0, 0, 0, 0)
	_voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_voile)

	var b := _boite(racine)
	_placer(b, 0.0, 0.0, 16, 16, 430)
	_etat = _texte(b)

	# Déroulé de l'intervention : les étapes, cochées au fur et à mesure (F1 pour masquer)
	_deroule_boite = _boite(racine)
	_placer(_deroule_boite, 0.0, 0.0, 16, 190, 400)
	_deroule = _texte(_deroule_boite)
	_deroule.add_theme_font_size_override("normal_font_size", 15)
	_deroule.add_theme_font_size_override("bold_font_size", 15)
	_deroule_boite.visible = false

	_ticket_boite = _boite(racine)
	_placer(_ticket_boite, 0.5, 0.0, -310, 16, 620)
	_ticket = _texte(_ticket_boite)
	_ticket_boite.visible = false

	var rb := _boite(racine)
	_placer(rb, 0.0, 1.0, 16, -16, 640)
	rb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_radio = _texte(rb)

	_victime_boite = _boite(racine)
	_placer(_victime_boite, 1.0, 0.0, -486, 16, 470)
	_victime = _texte(_victime_boite)
	_victime_boite.visible = false

	_fin_boite = _boite(racine)
	_placer(_fin_boite, 0.5, 0.5, -350, -260, 700)
	_fin = _texte(_fin_boite)
	_fin_boite.visible = false

	_invite = Label.new()
	_placer(_invite, 0.5, 0.5, -400, 60, 800)
	_invite.offset_bottom = 100
	_invite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_invite.add_theme_font_size_override("font_size", 22)
	_invite.add_theme_color_override("font_outline_color", Color.BLACK)
	_invite.add_theme_constant_override("outline_size", 6)
	_invite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_invite)

	_viseur = Label.new()
	_viseur.text = "+"
	_placer(_viseur, 0.5, 0.5, -7, -17, 14)
	_viseur.add_theme_font_size_override("font_size", 24)
	_viseur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_viseur)

	_aide = Label.new()
	_placer(_aide, 1.0, 1.0, -620, -150, 600)
	_aide.offset_bottom = -12
	_aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_aide.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_aide.add_theme_font_size_override("font_size", 14)
	_aide.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_aide.add_theme_color_override("font_outline_color", Color.BLACK)
	_aide.add_theme_constant_override("outline_size", 4)
	_aide.text = "Z Q S D (ou W A S D) : marcher · Maj : courir · Souris : regarder\nE : interagir · Clic gauche : arroser (lance en main)\n1 à 7 : gestes de secours près d'une victime\nT (maintenu) : accélérer un trajet · C : changer de vue en route · N : appel suivant\nF1 : afficher / masquer le déroulé · F2 : tirage équilibré / réaliste · Échap : libérer la souris"
	_aide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_aide)


## Place un élément par rapport à un coin ou au centre de l'écran.
func _placer(c: Control, ax: float, ay: float, ox: float, oy: float, largeur: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = ox
	c.offset_right = ox + largeur
	c.offset_top = oy
	c.offset_bottom = oy


func _boite(parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.82)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", style)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _texte(parent: Control) -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_theme_font_size_override("normal_font_size", 16)
	t.add_theme_font_size_override("bold_font_size", 16)
	parent.add_child(t)
	return t


func set_etat(bbcode: String) -> void:
	_etat.text = bbcode


func radio(qui: String, message: String, couleur: String = "#9fd3ff") -> void:
	_lignes_radio.append("[color=%s][b]%s[/b][/color] : %s" % [couleur, qui, message])
	while _lignes_radio.size() > 7:
		_lignes_radio.pop_front()
	_radio.text = "\n".join(PackedStringArray(_lignes_radio))


## Déroulé de l'intervention (vide = caché).
func set_deroule(bbcode: String) -> void:
	_deroule_boite.visible = bbcode != ""
	_deroule.text = bbcode


func afficher_ticket(bbcode: String) -> void:
	_ticket.text = bbcode
	_ticket_boite.visible = true


func cacher_ticket() -> void:
	_ticket_boite.visible = false


func ticket_visible() -> bool:
	return _ticket_boite.visible


func set_invite(t: String) -> void:
	_invite.text = t


func set_victime(bbcode: String) -> void:
	_victime_boite.visible = bbcode != ""
	_victime.text = bbcode


func afficher_fin(bbcode: String) -> void:
	_fin.text = bbcode
	_fin_boite.visible = true


func cacher_fin() -> void:
	_fin_boite.visible = false


func fin_visible() -> bool:
	return _fin_boite.visible


func set_viseur(v: bool) -> void:
	_viseur.visible = v


## Voile sombre (fondu) : 0 = invisible, 1 = noir.
func set_voile(a: float) -> void:
	_voile.color = Color(0, 0, 0, a)
