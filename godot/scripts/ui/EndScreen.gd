extends Control
## 1:1 canvas win / game over — HTML drawWin / drawGameOver / drawShareBtn / name entry.

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

var ctx: RefCounted
var bobina
var tick: int = 0
var share_btn: Dictionary = {}
var menu_btn: Dictionary = {}
var retry_btn: Dictionary = {}
var save_btn_rect: Dictionary = {}
var handle_edit: LineEdit
var _won: bool = false

func _ready() -> void:
	# Hide Control stubs from scene
	for c in get_children():
		if c is not LineEdit:
			c.visible = false
	handle_edit = LineEdit.new()
	handle_edit.placeholder_text = "@ X handle"
	handle_edit.position = Vector2(Config.W * 0.5 - 140, Config.H * 0.5 + 40)
	handle_edit.size = Vector2(280, 28)
	handle_edit.visible = false
	handle_edit.text_submitted.connect(func(t): _do_save(t))
	add_child(handle_edit)

	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	bobina = load("res://scripts/render/drawers/drawBobina.gd").new()
	bobina.setup(ctx)

	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	visible = false
	GameState.state_changed.connect(_on_state)
	GameState.run_ended.connect(_on_ended)

func _on_state(s: StringName) -> void:
	visible = s in [&"WIN", &"GAMEOVER"]
	if visible:
		_won = (GameState.state == GameState.State.WIN)
		P2Meta.end_won = _won
		queue_redraw()

func _on_ended(won: bool) -> void:
	_won = won
	P2Meta.end_won = won
	P2Meta.name_entry_open = false
	# HTML showNameEntry flow
	if ApiClient.authenticated:
		P2Meta.submit_score(str(ApiClient.me.get("xUsername", ProgressStore.progress.get("handle", ""))))
		handle_edit.visible = false
	else:
		P2Meta.name_entry_open = true
		handle_edit.visible = true
		handle_edit.text = str(ProgressStore.progress.get("handle", ""))
		handle_edit.grab_focus()
	queue_redraw()

func _process(_d: float) -> void:
	if not visible:
		return
	tick = SimClock.sim_frame if SimClock else tick + 1
	queue_redraw()

func _draw() -> void:
	if ctx == null:
		return
	ctx.begin_frame()
	share_btn = {}
	menu_btn = {}
	retry_btn = {}
	save_btn_rect = {}
	if _won:
		_draw_win()
	else:
		_draw_game_over()
	if P2Meta.name_entry_open and not ApiClient.authenticated:
		_draw_name_entry_chrome()

func _draw_game_over() -> void:
	var W = Config.W
	var H = Config.H
	ctx.fill_style("rgba(10,2,6,0.9)")
	ctx.fill_rect(0, 0, W, H)
	ctx.text_align("center")
	var img = AssetBank.get_tex("maid") if AssetBank else null
	var S = 200.0
	if img:
		ctx.draw_image(img, W / 2.0 - S / 2.0, 40, S, S)
		ctx.stroke_style("#ff5b6e")
		ctx.line_width(4)
		ctx.begin_path()
		ctx.round_rect(W / 2.0 - S / 2.0, 40, S, S, 14)
		ctx.stroke()
	ctx.save()
	ctx.shadow_color("#ff2b4e")
	ctx.shadow_blur(20)
	ctx.fill_style("#ff4d6d")
	ctx.font("900 46px Trebuchet MS")
	ctx.fill_text("GAME OVER", W / 2.0, 282)
	ctx.restore()
	ctx.fill_style("#ffd0dc")
	ctx.font("italic 16px Trebuchet MS")
	ctx.fill_text("“Aw shoot— dropped Bobo’s snacks AND the mission...”", W / 2.0, 308)
	ctx.fill_style("#e8cfe0")
	ctx.font("14px Trebuchet MS")
	ctx.fill_text("The LA Cabal still has Bobo. Regroup and hit back.", W / 2.0, 330)
	ctx.fill_style("#ff9ecb")
	ctx.font("bold 18px monospace")
	ctx.fill_text("%d Mumus  ·  Rank %s  ·  %s pts" % [
		GameState.total_kills, GameState.rank_letter(), MenuHelpers.fmt_score(GameState.session_score)
	], W / 2.0, 360)
	_draw_share_btn(W / 2.0, 378, false)
	menu_btn = _draw_menu_btn(W / 2.0, 420)
	ctx.text_align("center")
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 26.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 17px monospace")
	ctx.fill_text("PRESS " + MenuHelpers.kb("shoot") + " / TAP TO RETRY", W / 2.0, 470)
	retry_btn = {"x": W / 2.0 - 160, "y": 450, "w": 320, "h": 40}
	ctx.text_align("left")

func _draw_win() -> void:
	var W = Config.W
	var H = Config.H
	ctx.fill_style("#2a1030")
	ctx.fill_rect(0, 0, W, H * 0.55)
	ctx.fill_style("#4a1828")
	ctx.fill_rect(0, H * 0.45, W, H * 0.55)
	# floating hearts
	for i in range(24):
		var hx = fposmod(float(i) * 97.0 + float(tick) * 1.5, W)
		var hyy = H - fposmod(float(i) * 61.0 + float(tick) * 2.0, H)
		ctx.global_alpha(0.5)
		_draw_heart(hx, hyy, 6.0 + float(i % 3) * 2.0)
	ctx.global_alpha(1.0)
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(24)
	ctx.fill_style("#ffe08a")
	ctx.font("900 44px Trebuchet MS")
	ctx.fill_text("BOBO IS SAVED!", W / 2.0, 62)
	ctx.restore()
	var iw2 = 178.0
	var ih2 = 150.0
	var ix = W / 2.0 - iw2 / 2.0
	var iy = 78.0
	var cimg = AssetBank.get_tex("winimg") if AssetBank else null
	if cimg == null and AssetBank:
		cimg = AssetBank.get_tex("win")  # fallback key
	if cimg:
		ctx.draw_image(cimg, ix, iy, iw2, ih2)
		ctx.stroke_style("rgba(255,210,120,0.8)")
		ctx.line_width(3)
		ctx.begin_path()
		ctx.round_rect(ix, iy, iw2, ih2, 14)
		ctx.stroke()
	else:
		ctx.fill_style("rgba(255,255,255,0.05)")
		ctx.begin_path()
		ctx.round_rect(ix, iy, iw2, ih2, 14)
		ctx.fill()
		if bobina:
			bobina.set_outfit(GameState.selected_outfit)
			bobina.set_tick(tick)
			ctx.save()
			ctx.translate(W / 2.0 - 34, iy + ih2 - 20)
			bobina.drawBobina({"x": 0, "y": 0, "outfit": GameState.selected_outfit, "tick": tick, "face": -PI / 2.0})
			ctx.restore()
		ctx.stroke_style("rgba(255,210,120,0.6)")
		ctx.line_width(3)
		ctx.begin_path()
		ctx.round_rect(ix, iy, iw2, ih2, 14)
		ctx.stroke()
	var y = iy + ih2 + 24.0
	ctx.fill_style("#ff9ecb")
	ctx.font("italic 15px Trebuchet MS")
	ctx.fill_text("Every last Mumu exterminated. James Wynn finished. Dad is safe.", W / 2.0, y)
	y += 25
	ctx.fill_style("#fff")
	ctx.font("bold 16px monospace")
	ctx.fill_text("MUMU KILLS %d   ·   RANK %s   ·   SCORE %s" % [
		GameState.total_kills, GameState.rank_letter(), MenuHelpers.fmt_score(GameState.session_score)
	], W / 2.0, y)
	y += 22
	if GameState.difficulty > 0 or GameState.ng_plus > 0:
		ctx.fill_style("#ff5b6e" if GameState.difficulty >= 2 else "#ffd27a")
		ctx.font("bold 12px monospace")
		ctx.fill_text("— cleared on %s —" % GameState.mode_tag(), W / 2.0, y)
		y += 19
	# HTML winCabalUnlock celebration
	if ProgressStore.win_cabal_unlock:
		ctx.save()
		ctx.shadow_color("#ff2a00")
		ctx.shadow_blur(12)
		ctx.fill_style("#ff6a6a" if (int(floorf(float(tick) / 16.0)) % 2) != 0 else "#ffd27a")
		ctx.font("900 16px Trebuchet MS")
		ctx.fill_text("☠  CABAL SKIN UNLOCKED!  ☠", W / 2.0, y)
		ctx.restore()
		y += 21
	if ProgressStore.ng_unlocked > 0:
		ctx.fill_style("#8fd0a0")
		ctx.font("bold 12px monospace")
		ctx.fill_text("🔁 New Game+ Lv%d ready — pick it on the menu for ×%d points & tougher Mumus" % [
			ProgressStore.ng_unlocked, 1 + ProgressStore.ng_unlocked
		], W / 2.0, y)
		y += 19
	ctx.fill_style("#ffd27a")
	ctx.font("bold 13px monospace")
	ctx.fill_text("🏅 EMBLEMS EARNED  ·  %d/%d total" % [MenuHelpers.emblem_count(), DataRegistry.emblems.size()], W / 2.0, y)
	y += 17
	if P2Meta.new_emblems.is_empty():
		ctx.fill_style("#9a8ba8")
		ctx.font("italic 12px Trebuchet MS")
		ctx.fill_text("No new Emblems this run — check the 🏅 Emblems menu for more to chase.", W / 2.0, y)
	else:
		for id in P2Meta.new_emblems:
			var em = _emblem_def(str(id))
			if em.is_empty():
				continue
			ctx.fill_style("#8fd0ff")
			ctx.font("bold 12px monospace")
			var extra = "  — unlocked a skin!" if em.get("outfit") else ""
			ctx.fill_text("%s %s%s" % [em.get("icon", "★"), em.get("name", id), extra], W / 2.0, y)
			y += 15
	var sy = H - 104.0
	_draw_share_btn(W / 2.0, sy, true)
	menu_btn = _draw_menu_btn(W / 2.0, sy + 38)
	ctx.text_align("center")
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 26.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 14px monospace")
	ctx.fill_text("PRESS " + MenuHelpers.kb("shoot") + " / TAP TO PLAY AGAIN", W / 2.0, H - 14)
	retry_btn = {"x": W / 2.0 - 180, "y": H - 40, "w": 360, "h": 36}
	ctx.text_align("left")

func _draw_name_entry_chrome() -> void:
	var W = Config.W
	var H = Config.H
	ctx.fill_style("rgba(8,4,14,0.72)")
	ctx.fill_rect(W * 0.5 - 220, H * 0.5 - 30, 440, 110)
	ctx.stroke_style("#ff9ecb")
	ctx.line_width(2)
	ctx.begin_path()
	ctx.round_rect(W * 0.5 - 220, H * 0.5 - 30, 440, 110, 10)
	ctx.stroke()
	ctx.text_align("center")
	ctx.fill_style("#ffe08a")
	ctx.font("bold 14px Trebuchet MS")
	var prefix = "BOBO SAVED! " if _won else ""
	ctx.fill_text("%sScore %s · %d Mumus · Rank %s" % [
		prefix, MenuHelpers.fmt_score(GameState.session_score), GameState.total_kills, GameState.rank_letter()
	], W / 2.0, H * 0.5 - 8)
	ctx.fill_style("#c8b0d0")
	ctx.font("11px monospace")
	ctx.fill_text("Save your X handle for credit — or Sign in with Bobina", W / 2.0, H * 0.5 + 12)
	# SAVE button under input
	var bx = W * 0.5 - 80
	var by = H * 0.5 + 72
	save_btn_rect = {"x": bx, "y": by, "w": 160, "h": 28}
	ctx.fill_style("rgba(255,90,140,0.35)")
	ctx.begin_path()
	ctx.round_rect(bx, by, 160, 28, 8)
	ctx.fill()
	ctx.fill_style("#fff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.fill_text("SAVE SCORE", W / 2.0, by + 19)
	handle_edit.position = Vector2(W * 0.5 - 140, H * 0.5 + 28)
	handle_edit.visible = true
	ctx.text_align("left")

func _draw_share_btn(cx: float, y: float, won: bool) -> void:
	var w = 272.0
	var h = 34.0
	var x = cx - w / 2.0
	share_btn = {"x": x, "y": y, "w": w, "h": h, "won": won}
	if P2Meta.just_saved_score:
		ctx.fill_style("#7ed957")
		ctx.font("bold 12px monospace")
		ctx.text_align("center")
		ctx.fill_text("✓ Saved to the global leaderboard — flex it below!", cx, y - 9)
	ctx.fill_style("#000")
	ctx.begin_path()
	ctx.round_rect(x, y, w, h, 8)
	ctx.fill()
	ctx.stroke_style("#3a3a3a")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#fff")
	ctx.font("bold 17px Georgia")
	ctx.text_align("center")
	ctx.fill_text("X", x + 24, y + 23)
	ctx.font("bold 15px Trebuchet MS")
	ctx.fill_text("Share your result", cx + 12, y + 22)
	ctx.text_align("left")

func _draw_menu_btn(cx: float, y: float) -> Dictionary:
	var w = 150.0
	var h = 28.0
	var x = cx - w / 2.0
	var b = {"x": x, "y": y, "w": w, "h": h}
	ctx.fill_style("rgba(30,16,40,0.85)")
	ctx.begin_path()
	ctx.round_rect(x, y, w, h, 8)
	ctx.fill()
	ctx.stroke_style("#8fd0ff")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.text_align("center")
	ctx.fill_text("⌂ MAIN MENU  [M]", cx, y + 19)
	ctx.text_align("left")
	return b

func _draw_heart(x: float, y: float, s: float) -> void:
	ctx.fill_style("#ff6ec7")
	ctx.begin_path()
	ctx.arc(x - s * 0.35, y, s * 0.4, 0, TAU)
	ctx.arc(x + s * 0.35, y, s * 0.4, 0, TAU)
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(x - s * 0.7, y)
	ctx.line_to(x, y + s * 0.85)
	ctx.line_to(x + s * 0.7, y)
	ctx.fill()

func _emblem_def(id: String) -> Dictionary:
	for e in DataRegistry.emblems:
		if str(e.get("id")) == id:
			return e
	return {}

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("shoot") or event.keycode == KEY_ENTER:
			if P2Meta.name_entry_open and handle_edit.visible:
				_do_save(handle_edit.text)
			else:
				_retry()
			accept_event()
			return
		if event.keycode == KEY_M:
			_menu()
			accept_event()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if MenuHelpers.in_btn(p, share_btn):
			P2Meta.tweet_result(_won)
			accept_event()
			return
		if MenuHelpers.in_btn(p, menu_btn):
			_menu()
			accept_event()
			return
		if MenuHelpers.in_btn(p, save_btn_rect):
			_do_save(handle_edit.text)
			accept_event()
			return
		if MenuHelpers.in_btn(p, retry_btn) or true:
			# empty tap retries like HTML advanceScreen for end states
			if not P2Meta.name_entry_open:
				_retry()
			accept_event()

func _do_save(handle: String) -> void:
	P2Meta.do_save_score(handle)
	handle_edit.visible = false
	P2Meta.name_entry_open = false
	queue_redraw()

func _retry() -> void:
	handle_edit.visible = false
	P2Meta.name_entry_open = false
	GameState.start_run()

func _menu() -> void:
	handle_edit.visible = false
	P2Meta.name_entry_open = false
	GameState.ng_plus = mini(GameState.ng_plus, ProgressStore.ng_unlocked)
	GameState.return_to_title()

# Legacy scene buttons
func _on_save() -> void:
	_do_save(handle_edit.text if handle_edit else "")
func _on_again() -> void:
	_retry()
func _on_menu() -> void:
	_menu()
