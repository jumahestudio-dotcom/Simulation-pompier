## Sons fabriqués par le programme (pas de fichier audio).
## mode "deux_tons" : sirène française (deux notes alternées).
## mode "alarme" : sonnerie de déclenchement en caserne.
extends AudioStreamPlayer3D

const FREQ := 22050.0

var mode := "deux_tons"
var actif := false
var _gen: AudioStreamGeneratorPlayback
var _phase := 0.0
var _t := 0.0


func _ready() -> void:
	var s := AudioStreamGenerator.new()
	s.mix_rate = FREQ
	s.buffer_length = 0.15
	stream = s
	unit_size = 30.0
	max_db = 0.0
	volume_db = -8.0
	play()
	_gen = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if _gen == null:
		return
	var n: int = _gen.get_frames_available()
	for i in n:
		var v := 0.0
		if actif:
			_t += 1.0 / FREQ
			var f := 0.0
			if mode == "deux_tons":
				# Deux notes (environ la et si), un peu plus d'une demi-seconde chacune.
				f = 435.0 if fmod(_t, 1.3) < 0.65 else 488.0
			else:
				f = 880.0 if fmod(_t, 0.5) < 0.3 else 0.0
			if f > 0.0:
				_phase = fmod(_phase + f / FREQ, 1.0)
				var x: float = _phase * TAU
				v = (sin(x) + 0.35 * sin(3.0 * x) + 0.2 * sin(5.0 * x)) * 0.22
		_gen.push_frame(Vector2(v, v))
