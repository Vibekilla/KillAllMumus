extends Node
## 1:1 port of HTML sfx() — oscillator envelopes as AudioStreamWAV (Web-safe).
## AudioStreamGenerator + push_frame fails on HTML5 ("stream that cannot be sampled").
## Types: shoot, hit, kill, graze, item, power, extend, bomb, hurt, card, win,
## slash, whip, thud, boom, claw, warp

var sfx_volume: float = 0.9
var music_volume: float = 1.0
var _players: Array = []
const POOL := 12
const RATE := 22050

func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)

func play(type: String, vmul: float = 1.0) -> void:
	var vm := sfx_volume * vmul
	match type:
		"shoot":
			_beep(1100, 620, 0.07, "triangle", 0.035 * vm)
		"hit":
			_beep(300, 140, 0.06, "square", 0.05 * vm)
		"kill":
			_beep(180, 70, 0.13, "sawtooth", 0.07 * vm)
		"graze":
			_beep(1500, 2300, 0.05, "sine", 0.03 * vm)
		"item":
			_beep(900, 1500, 0.06, "triangle", 0.05 * vm)
		"power":
			_beep(700, 1400, 0.12, "square", 0.06 * vm)
		"extend":
			var fs := [660.0, 880.0, 1320.0]
			for i in fs.size():
				_beep_delayed(fs[i], fs[i], 0.3, "triangle", 0.1 * vm, float(i) * 0.09)
		"bomb":
			_beep(120, 900, 0.5, "sawtooth", 0.14 * vm)
		"hurt":
			_beep(240, 70, 0.35, "square", 0.16 * vm)
		"card":
			var cf := [180.0, 300.0, 240.0]
			for i in cf.size():
				_beep_delayed(cf[i], cf[i] * 0.5, 0.25, "sawtooth", 0.1 * vm, float(i) * 0.08)
		"win":
			var wf := [523.0, 659.0, 784.0, 1046.0, 1318.0]
			for i in wf.size():
				_beep_delayed(wf[i], wf[i], 0.3, "triangle", 0.1 * vm, float(i) * 0.1)
		"slash":
			_beep(2600, 760, 0.14, "sawtooth", 0.055 * vm)
		"whip":
			_beep(1500, 150, 0.18, "sine", 0.075 * vm)
		"thud":
			_beep(170, 46, 0.18, "square", 0.15 * vm)
		"boom":
			# HTML: two saws f*3 → f over 0.42s
			_beep(330, 110, 0.46, "sawtooth", 0.16 * vm)
			_beep_delayed(216, 72, 0.46, "sawtooth", 0.16 * vm, 0.02)
		"claw":
			# HTML triple scratch at 1900/2300/1650
			var clawf := [1900.0, 2300.0, 1650.0]
			for i in clawf.size():
				_beep_delayed(clawf[i], clawf[i] * 0.5, 0.08, "sawtooth", 0.055 * vm, float(i) * 0.045)
		"warp":
			# HTML: 180 → 1400 (0.18s) → 90 (0.5s total) single osc — approximate with two legs
			_beep(180, 1400, 0.18, "sine", 0.13 * vm)
			_beep_delayed(1400, 90, 0.32, "sine", 0.13 * vm, 0.18)
		_:
			_beep(440, 220, 0.08, "square", 0.04 * vm)

func _beep(f0: float, f1: float, dur: float, wave: String, vol: float) -> void:
	_beep_delayed(f0, f1, dur, wave, vol, 0.0)

func _beep_delayed(f0: float, f1: float, dur: float, wave: String, vol: float, delay: float) -> void:
	if vol <= 0.0001:
		return
	# Fire-and-forget coroutine
	_play_wav_async(f0, f1, dur, wave, vol, delay)

func _play_wav_async(f0: float, f1: float, dur: float, wave: String, vol: float, delay: float) -> void:
	var stream := _make_wav(f0, f1, dur, wave, vol)
	if stream == null:
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var player: AudioStreamPlayer = _acquire()
	if player == null:
		return
	player.stop()
	player.stream = stream
	player.volume_db = 0.0
	player.play()

func _make_wav(f0: float, f1: float, dur: float, wave: String, vol: float) -> AudioStreamWAV:
	## Offline PCM — works on desktop + HTML5 (unlike live AudioStreamGenerator push)
	var nframes := maxi(1, int(dur * float(RATE)) + 1)
	var data := PackedByteArray()
	data.resize(nframes * 2)  # mono 16-bit
	var phase := 0.0
	for i in nframes:
		var t := float(i) / float(nframes)
		var freq := lerpf(f0, f1, t)
		if freq < 20.0:
			freq = 20.0
		phase += TAU * freq / float(RATE)
		var s := 0.0
		match wave:
			"sine":
				s = sin(phase)
			"square":
				s = 1.0 if fmod(phase, TAU) < PI else -1.0
			"sawtooth":
				s = fmod(phase / TAU, 1.0) * 2.0 - 1.0
			"triangle":
				var u := fmod(phase / TAU, 1.0)
				s = (u * 4.0 - 1.0) if u < 0.5 else (3.0 - u * 4.0)
			_:
				s = sin(phase)
		# HTML WebAudio-style attack + exponential decay
		var attack := clampf(t / 0.04, 0.0, 1.0) if t < 0.04 else 1.0
		var env := attack * exp(-4.2 * t) * (1.0 - t * 0.12)
		var sample := clampf(s * env * 0.38 * vol * 4.0, -1.0, 1.0)
		var si := int(round(sample * 32767.0))
		si = clampi(si, -32768, 32767)
		# little-endian int16
		data[i * 2] = si & 0xFF
		data[i * 2 + 1] = (si >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream

func _acquire() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0] if _players.size() else null
