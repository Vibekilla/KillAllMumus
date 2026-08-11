extends Control
## HTML #soundgate — first-run / every-session play gate (fullscreen + sound / muted).
## HTML shows the gate on each page load until the user taps (user-gesture for autoplay).
## Music: MusicBridge → YT lofi (same ID as public/index.html).

signal dismissed(with_sound: bool)

var _open: bool = true
var _campfire: Texture2D
var _play_btn: Rect2
var _mute_btn: Rect2
var _card: Rect2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("sound_gate")
	if AssetBank and AssetBank.has_method("get_tex"):
		_campfire = AssetBank.get_tex("campfire")
	# Dual / headless only — never skip for normal web/desktop (HTML re-shows every load)
	var auto_skip := OS.has_feature("headless") \
		or OS.get_environment("PLAYTEST_FAST") != "" \
		or OS.get_environment("PLAYTEST_FULL") != "" \
		or OS.get_environment("SKIP_SOUNDGATE") == "1" \
		or OS.get_environment("PLAYTEST_SHOTS") != ""
	if auto_skip:
		_open = false
		visible = false
	else:
		# Session gate only — do not honor permanent soundgate_seen for skip
		# (persisting it left returning users with no music and no user gesture).
		_open = true
		visible = true
		queue_redraw()
	set_process_unhandled_input(true)
	set_process(false)

func _unhandled_input(event: InputEvent) -> void:
	## While open, eat keyboard so Z/X cannot start/play under the modal (HTML gate blocks keys).
	if not is_blocking():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# Enter / Space / Z dismiss like tapping play-with-sound for accessibility
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z]:
			_dismiss(true)
		get_viewport().set_input_as_handled()

func force_dismiss(with_sound: bool = false) -> void:
	## Used by screenshot/playtest harness
	if _open:
		_dismiss(with_sound)
	else:
		visible = false

func force_open() -> void:
	## Dual / QA — re-show gate
	_open = true
	visible = true
	queue_redraw()

func is_blocking() -> bool:
	return _open and visible

func _draw() -> void:
	if not _open:
		return
	var W := size.x if size.x > 1.0 else Config.W
	var H := size.y if size.y > 1.0 else Config.H
	# HTML radial backdrop
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.016, 0.05, 0.97))
	# Card — HTML .sg-card gradient + pink border glow
	var cw := minf(440.0, W * 0.94)
	var ch := minf(400.0, H * 0.92)
	var cx := (W - cw) * 0.5
	var cy := (H - ch) * 0.5
	_card = Rect2(cx, cy, cw, ch)
	# soft glow
	draw_rect(Rect2(cx - 4, cy - 4, cw + 8, ch + 8), Color(1.0, 0.24, 0.47, 0.12), true)
	draw_rect(_card, Color(0.18, 0.08, 0.19, 0.98), true)  # #2a1830-ish
	draw_rect(_card, Color(1.0, 0.357, 0.553, 0.95), false, 2.5)  # #ff5b8d
	# Image
	var pad := 16.0
	var img_w := cw - pad * 2.0
	var img_h := img_w * 9.0 / 16.0
	img_h = minf(img_h, ch * 0.42)
	var ix := cx + pad
	var iy := cy + pad
	var img_r := Rect2(ix, iy, img_w, img_h)
	if _campfire:
		draw_texture_rect(_campfire, img_r, false)
	else:
		draw_rect(img_r, Color(0.25, 0.12, 0.1))
	draw_rect(img_r, Color(1.0, 0.71, 0.31, 0.55), false, 2.0)
	# Title / sub
	var f := FontBank.default_font() if FontBank else ThemeDB.fallback_font
	var fb := FontBank.ui_bold if FontBank and FontBank.ui_bold else f
	var ty := iy + img_h + 22.0
	draw_string(fb, Vector2(cx + pad, ty), "BOBINA: KILL ALL MUMUS!!", HORIZONTAL_ALIGNMENT_LEFT, int(cw - pad * 2), 20, Color(1.0, 0.878, 0.541))
	ty += 28.0
	var sub := "Best played fullscreen with sound — tap Play to launch with Bobina's lofi beats at full volume."
	var line1 := sub
	var line2 := ""
	if sub.length() > 52:
		var cut := 52
		while cut > 20 and sub[cut] != " ":
			cut -= 1
		line1 = sub.substr(0, cut)
		line2 = sub.substr(cut).strip_edges()
	draw_string(f, Vector2(cx + pad, ty), line1, HORIZONTAL_ALIGNMENT_LEFT, int(cw - pad * 2), 12, Color(0.91, 0.81, 0.88))
	if line2 != "":
		ty += 16.0
		draw_string(f, Vector2(cx + pad, ty), line2, HORIZONTAL_ALIGNMENT_LEFT, int(cw - pad * 2), 12, Color(0.91, 0.81, 0.88))
	# Buttons (HTML #sg-enable / #sg-mute)
	var by := cy + ch - 118.0
	_play_btn = Rect2(cx + pad, by, cw - pad * 2.0, 48.0)
	_mute_btn = Rect2(cx + pad, by + 56.0, cw - pad * 2.0, 40.0)
	draw_rect(_play_btn, Color(1.0, 0.357, 0.553, 0.98), true)
	draw_rect(_play_btn, Color(1.0, 0.75, 0.85, 0.55), false, 1.5)
	draw_string(fb, Vector2(_play_btn.position.x + 28, _play_btn.position.y + 30), "▶ PLAY — FULLSCREEN & SOUND", HORIZONTAL_ALIGNMENT_LEFT, int(_play_btn.size.x - 40), 15, Color(1, 1, 1))
	draw_rect(_mute_btn, Color(1, 1, 1, 0.05), true)
	draw_rect(_mute_btn, Color(1, 1, 1, 0.18), false, 1.0)
	draw_string(f, Vector2(_mute_btn.position.x + 90, _mute_btn.position.y + 26), "Play fullscreen, muted", HORIZONTAL_ALIGNMENT_LEFT, int(_mute_btn.size.x - 100), 12, Color(0.784, 0.69, 0.769))
	draw_string(f, Vector2(cx + pad, cy + ch - 14), "A Bobina Council LLC & Grr Finance production", HORIZONTAL_ALIGNMENT_LEFT, int(cw - pad * 2), 10, Color(0.604, 0.545, 0.659))

func _gui_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if not st.pressed:
			return
		_try_click(st.position)
		accept_event()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_try_click(mb.position)
		accept_event()

func _try_click(pos: Vector2) -> void:
	if _play_btn.has_point(pos):
		_dismiss(true)
	elif _mute_btn.has_point(pos):
		_dismiss(false)

func _dismiss(with_sound: bool) -> void:
	_open = false
	visible = false
	# Session marker only (in-memory) — optional analytics; not used to skip gate next load
	if ProgressStore:
		ProgressStore.progress["soundgate_seen"] = true
		ProgressStore.progress["lofiOn"] = with_sound
		if ProgressStore.has_method("queue_save"):
			ProgressStore.queue_save()
	if with_sound:
		# HTML: lofiOn=true; initMaster(); musicPlay(); closeGate(true)
		if AudioBus:
			AudioBus.set_music_volume(1.0)
			if ProgressStore and ProgressStore.progress.get("settings") is Dictionary:
				var st: Dictionary = ProgressStore.progress["settings"]
				if st.has("music"):
					var m := float(st["music"])
					AudioBus.set_music_volume((m / 100.0) if m > 1.0 else m)
		if MusicBridge:
			MusicBridge.play()
		_request_fullscreen_like_html()
	else:
		# HTML: lofiOn=false; closeGate(true) — still fullscreen on mobile, no music
		if AudioBus:
			AudioBus.set_music_volume(0.0)
		if MusicBridge:
			MusicBridge.pause()
		_request_fullscreen_like_html()
	if AudioBus:
		AudioBus.sfx("item")
	dismissed.emit(with_sound)

func _request_fullscreen_like_html() -> void:
	## HTML goFullscreenMobile — only on touch devices (desktop stays windowed)
	var touch := DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		if ClassDB.class_exists("JavaScriptBridge"):
			# Best-effort; desktop no-op matches HTML
			JavaScriptBridge.eval(
				"try{if(('ontouchstart' in window)||navigator.maxTouchPoints>0){var el=document.documentElement;var rf=el.requestFullscreen||el.webkitRequestFullscreen;if(rf&&!document.fullscreenElement&&!document.webkitFullscreenElement){var r=rf.call(el);if(r&&r.catch)r.catch(function(){});}}}catch(e){}",
				true
			)
		return
	if touch and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
