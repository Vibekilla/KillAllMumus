extends Control
## HTML #soundgate — first-run play gate (fullscreen + sound / muted).
## Modular overlay; does not wrap the HTML game. Music stream is optional web bridge later.

signal dismissed(with_sound: bool)

var _open: bool = true
var _campfire: Texture2D
var _play_btn: Rect2
var _mute_btn: Rect2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 80
	if AssetBank and AssetBank.has_method("get_tex"):
		_campfire = AssetBank.get_tex("campfire")
	# Skip for automated dual/playtest (HTML dual also clicks #sg-mute)
	var auto_skip := OS.has_feature("headless") \
		or OS.get_environment("PLAYTEST_FAST") != "" \
		or OS.get_environment("PLAYTEST_FULL") != "" \
		or OS.get_environment("SKIP_SOUNDGATE") == "1"
	if auto_skip or (ProgressStore and ProgressStore.progress.get("soundgate_seen", false)):
		_open = false
		visible = false
	else:
		visible = true
		queue_redraw()
	set_process(false)

func force_dismiss(with_sound: bool = false) -> void:
	## Used by screenshot/playtest harness
	if _open:
		_dismiss(with_sound)
	else:
		visible = false

func is_blocking() -> bool:
	return _open and visible

func _draw() -> void:
	if not _open:
		return
	var W := Config.W
	var H := Config.H
	# Dim backdrop
	draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.02, 0.08, 0.92))
	# Card
	var cw := 420.0
	var ch := 360.0
	var cx := (W - cw) * 0.5
	var cy := (H - ch) * 0.5
	draw_rect(Rect2(cx, cy, cw, ch), Color(0.12, 0.06, 0.16, 0.98), true)
	draw_rect(Rect2(cx, cy, cw, ch), Color(1.0, 0.62, 0.8, 0.55), false, 2.0)
	# Campfire image
	var img_h := 120.0
	var img_w := 200.0
	var ix := cx + (cw - img_w) * 0.5
	var iy := cy + 18.0
	if _campfire:
		draw_texture_rect(_campfire, Rect2(ix, iy, img_w, img_h), false)
	else:
		draw_rect(Rect2(ix, iy, img_w, img_h), Color(0.3, 0.15, 0.1))
	# Title / sub
	var f := FontBank.default_font() if FontBank else ThemeDB.fallback_font
	var fb := FontBank.ui_bold if FontBank and FontBank.ui_bold else f
	draw_string(fb, Vector2(cx + cw * 0.5 - 140, iy + img_h + 28), "BOBINA: KILL ALL MUMUS!!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.88, 0.55))
	var sub := "Best played fullscreen with sound — tap Play to launch with Bobina's lofi beats."
	draw_string(f, Vector2(cx + 24, iy + img_h + 52), sub.substr(0, 48), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.75, 0.88))
	draw_string(f, Vector2(cx + 24, iy + img_h + 68), sub.substr(48) if sub.length() > 48 else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.75, 0.88))
	# Buttons
	var by := cy + ch - 110.0
	_play_btn = Rect2(cx + 40, by, cw - 80, 36)
	_mute_btn = Rect2(cx + 40, by + 44, cw - 80, 32)
	draw_rect(_play_btn, Color(1.0, 0.35, 0.55, 0.95), true)
	draw_rect(_play_btn, Color(1.0, 0.75, 0.85, 0.8), false, 1.5)
	draw_string(fb, Vector2(_play_btn.position.x + 48, _play_btn.position.y + 24), "▶ PLAY — FULLSCREEN & SOUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1))
	draw_rect(_mute_btn, Color(0.15, 0.08, 0.18, 0.95), true)
	draw_rect(_mute_btn, Color(0.45, 0.3, 0.4, 0.9), false, 1.0)
	draw_string(f, Vector2(_mute_btn.position.x + 90, _mute_btn.position.y + 21), "Play fullscreen, muted", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.85, 0.92))
	draw_string(f, Vector2(cx + 70, cy + ch - 18), "A Bobina Council LLC & Grr Finance production", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.45, 0.58))

func _gui_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if _play_btn.has_point(mb.position):
			_dismiss(true)
			accept_event()
		elif _mute_btn.has_point(mb.position):
			_dismiss(false)
			accept_event()

func _dismiss(with_sound: bool) -> void:
	_open = false
	visible = false
	if ProgressStore:
		ProgressStore.progress["soundgate_seen"] = true
		if ProgressStore.has_method("queue_save"):
			ProgressStore.queue_save()
	if with_sound:
		if AudioBus:
			AudioBus.set_sfx_volume(AudioBus.sfx_volume)
			AudioBus.set_music_volume(1.0)
		# HTML: lofiOn=true; musicPlay()
		if MusicBridge:
			MusicBridge.play()
		# Best-effort fullscreen (web/desktop)
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if AudioBus:
			AudioBus.set_music_volume(0.0)
		if MusicBridge:
			MusicBridge.pause()
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if AudioBus:
		AudioBus.sfx("item")
	dismissed.emit(with_sound)
