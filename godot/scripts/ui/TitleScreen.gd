extends Control
const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")
const MenuModelScript = preload("res://scripts/ui/menu/MenuModel.gd")
## Full canvas menu host — HTML title + outfits + emblems + NG+ + arsenal + leaderboard.

signal start_pressed
signal leaderboard_pressed
signal settings_pressed
signal outfits_pressed
signal emblems_pressed
signal arsenal_pressed
signal ng_pressed
signal login_pressed
signal shoutouts_pressed

const MENU_STATES := [
	GameState.State.TITLE,
	GameState.State.OUTFITS,
	GameState.State.EMBLEMS,
	GameState.State.ARSENAL,
	GameState.State.NG_SELECT,
	GameState.State.LEADERBOARD,
]

var ctx: RefCounted
var title_drawer: RefCounted
var menus: RefCounted
var model
var bobina
var title_idle_t: float = 0.0
var _last_draw_tick: int = -1
var _login_btn: Button
var _auth_label: Label
var _pointer_down = false

func _ready() -> void:
	# Hide Control stub children (VBox / Backdrop)
	for c in get_children():
		if c.name in ["VBox", "Backdrop"]:
			c.visible = false
	# HTML #bobinaAuth — centered above social strip (bottom ~52px on desktop)
	_auth_label = Label.new()
	_auth_label.name = "CanvasAuthLabel"
	_auth_label.add_theme_font_size_override("font_size", 11)
	_auth_label.add_theme_color_override("font_color", Color(1, 0.82, 0.9))
	_auth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auth_label.clip_text = true
	_auth_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_auth_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_auth_label)
	_login_btn = Button.new()
	_login_btn.name = "CanvasLoginBtn"
	_login_btn.clip_text = true
	_login_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_login_btn.pressed.connect(_on_login_pressed)
	add_child(_login_btn)
	_layout_auth_chrome()

	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	model = MenuModelScript.new()
	model.load_prefs()
	bobina = load("res://scripts/render/drawers/drawBobina.gd").new()
	bobina.setup(ctx)
	title_drawer = load("res://scripts/render/drawers/drawTitle.gd").new()
	title_drawer.setup(ctx)
	title_drawer.set_bobina(bobina)
	# Phase 1: cache full drawBobina for expensive outfit previews
	var bob_cache = get_node_or_null("BobinaDrawCache")
	if bob_cache == null:
		bob_cache = load("res://scripts/render/BobinaDrawCache.gd").new()
		bob_cache.name = "BobinaDrawCache"
		add_child(bob_cache)
	menus = load("res://scripts/ui/menu/draw_menus.gd").new()
	menus.setup(ctx, model, bobina, bob_cache)

	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_refresh_auth()
	ApiClient.auth_changed.connect(func(_a): _refresh_auth())
	ApiClient.scores_received.connect(_on_scores)
	if ApiClient.has_signal("scores_failed"):
		ApiClient.scores_failed.connect(_on_scores_failed)
	GameState.state_changed.connect(_on_state)
	_sync_visible(GameState.state)
	queue_redraw()

func _on_scores(scores: Array) -> void:
	model.lb_cache = scores if scores != null else []
	# Empty array after a real response is "ok" (no scores yet); null/failed → error
	model.lb_state = "ok"
	model.lb_page = 0
	queue_redraw()

func _on_scores_failed() -> void:
	model.lb_state = "error"
	model.lb_cache = []
	queue_redraw()

func _on_state(s: StringName) -> void:
	var st = GameState.state
	_sync_visible(st)
	if st == GameState.State.TITLE:
		title_idle_t = 0.0
		model.load_prefs()
		_refresh_auth()
	elif st == GameState.State.OUTFITS:
		model.outfit_preview = GameState.selected_outfit
		model.outfit_anim_t = 0
	elif st == GameState.State.EMBLEMS:
		model.em_page = 0
	elif st == GameState.State.ARSENAL:
		model.ars_tab = "w"
		model.ars_drag = null
		model.arsenal_return = "title"
	elif st == GameState.State.LEADERBOARD:
		model.lb_state = "loading"
		model.lb_cache = []
		model.lb_page = 0
		ApiClient.fetch_scores()
	queue_redraw()

func _sync_visible(st: GameState.State) -> void:
	visible = st in MENU_STATES
	# Auth is drawn on canvas (HTML #bobinaAuth) — hide Control stubs
	if _login_btn:
		_login_btn.visible = false
	if _auth_label:
		_auth_label.visible = false

func _is_touch_ui() -> bool:
	## HTML body.touch class — force desktop layout under dual/playtest
	if OS.get_environment("PLAYTEST_FAST") != "" or OS.get_environment("PLAYTEST_FULL") != "":
		return false
	if OS.has_feature("headless"):
		return false
	return DisplayServer.is_touchscreen_available()

func _layout_auth_chrome() -> void:
	## Match HTML #bobinaAuth: centered, above #social strip (~28px chips)
	if _login_btn == null or _auth_label == null:
		return
	var touch := _is_touch_ui()
	var btn_w := 220.0
	var btn_h := 26.0
	var bottom := 10.0 if touch else 54.0  # desktop leaves room for social bar
	_login_btn.size = Vector2(btn_w, btn_h)
	_login_btn.position = Vector2((Config.W - btn_w) * 0.5, Config.H - bottom - btn_h)
	_auth_label.size = Vector2(420, 16)
	_auth_label.position = Vector2((Config.W - 420.0) * 0.5, _login_btn.position.y - 18.0)

func _refresh_auth() -> void:
	if _auth_label == null:
		return
	if ApiClient.authenticated:
		_auth_label.text = "Signed in as @%s" % str(ApiClient.me.get("username", "Bobina"))
		_login_btn.text = "Cloud sync ready"
	else:
		_auth_label.text = "Play as guest — or link Bobina for cloud saves"
		_login_btn.text = "Sign in with Bobina"
	_layout_auth_chrome()

func _process(delta: float) -> void:
	if not visible:
		return
	if GameState.state == GameState.State.TITLE:
		title_idle_t += delta * 60.0
	# ctx/title_drawer can be null if CanvasCompat failed to load — guard hard
	if ctx == null or title_drawer == null or menus == null:
		return
	var t: int = int(SimClock.tick) if SimClock else int(title_drawer.tick) + 1
	# Throttle full-canvas redraws to sim tick (~60 Hz) — was redrawing every render frame
	if t == _last_draw_tick and GameState.state != GameState.State.TITLE:
		return
	# Title still needs idle animation, but only when tick advances
	if t == _last_draw_tick:
		return
	# Title drawBobina is very expensive — 30 Hz is enough for particles + idle bob
	if GameState.state == GameState.State.TITLE and title_idle_t <= 1800.0 and (t % 2) != 0:
		return
	_last_draw_tick = t
	if title_drawer.has_method("set_tick"):
		title_drawer.set_tick(t)
	if menus.has_method("set_tick"):
		menus.set_tick(t)
	if bobina and bobina.has_method("set_tick"):
		bobina.set_tick(t)
	queue_redraw()

func _draw() -> void:
	if ctx == null:
		return
	ctx.begin_frame()
	model.reset_hits()
	var t: int = int(SimClock.tick) if SimClock else int(title_drawer.tick)
	match GameState.state:
		GameState.State.TITLE:
			title_drawer.set_menu_state({
				"outfit": GameState.selected_outfit,
				"tick": t,
				"title_idle_t": title_idle_t,
				"is_touch": _is_touch_ui(),
				"difficulty": GameState.difficulty,
				"ng_plus": GameState.ng_plus,
				"ng_unlocked": ProgressStore.ng_unlocked,
			})
			title_drawer.drawTitle()
			model.title_btns = title_drawer.title_btns
		GameState.State.OUTFITS:
			menus.draw_outfits()
		GameState.State.EMBLEMS:
			menus.draw_emblems()
		GameState.State.NG_SELECT:
			menus.draw_ng_select()
		GameState.State.ARSENAL:
			menus.draw_arsenal()
		GameState.State.LEADERBOARD:
			menus.draw_leaderboard()
	if P2Meta.shoutouts_open:
		_draw_shoutouts()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	# Shoot / Enter returns from submenus
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("shoot") or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			if GameState.state == GameState.State.TITLE:
				if title_idle_t > 1800.0:
					_start()
				elif event.is_action_pressed("shoot") or event.keycode == KEY_ENTER:
					_start()
			else:
				_return_title()
			accept_event()
			return
		# any key during maid dance
		if GameState.state == GameState.State.TITLE and title_idle_t > 1800.0:
			_start()
			accept_event()
			return
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pointer_down = true
			title_idle_t = 0.0
			_on_pointer_down(mb.position)
			accept_event()
		else:
			if _pointer_down:
				_on_pointer_up(mb.position)
			_pointer_down = false
			accept_event()
	elif event is InputEventMouseMotion and _pointer_down:
		_on_pointer_move(event.position)
		accept_event()

func _on_pointer_down(p: Vector2) -> void:
	if P2Meta.shoutouts_open:
		if MenuHelpers.in_btn(p, _shout_close):
			P2Meta.close_shoutouts()
			return
		for r in _shout_hits:
			if MenuHelpers.in_btn(p, r):
				OS.shell_open(str(r.get("url", "")))
				return
		P2Meta.close_shoutouts()
		return
	match GameState.state:
		GameState.State.TITLE:
			_handle_title_click(p)
		GameState.State.OUTFITS:
			_handle_outfits(p)
		GameState.State.EMBLEMS:
			_handle_emblems(p)
		GameState.State.NG_SELECT:
			_handle_ng(p)
		GameState.State.ARSENAL:
			_handle_arsenal_down(p)
		GameState.State.LEADERBOARD:
			_handle_lb(p)

func _on_pointer_move(p: Vector2) -> void:
	if GameState.state != GameState.State.ARSENAL:
		return
	var d = model.ars_drag
	if d == null or typeof(d) != TYPE_DICTIONARY:
		return
	d["x"] = p.x
	d["y"] = p.y
	if not bool(d.get("moved", false)):
		var dx = p.x - float(d.get("sx", p.x))
		var dy = p.y - float(d.get("sy", p.y))
		if sqrt(dx * dx + dy * dy) > 7.0:
			d["moved"] = true
	queue_redraw()

func _on_pointer_up(p: Vector2) -> void:
	if GameState.state == GameState.State.ARSENAL:
		_handle_arsenal_up(p)

func _handle_title_click(p: Vector2) -> void:
	if title_idle_t > 1800.0:
		_start()
		return
	# HTML #social chip clicks
	if title_drawer and "social_hits" in title_drawer:
		for s in title_drawer.social_hits:
			if MenuHelpers.in_btn(p, s):
				var url := str(s.get("url", ""))
				if url != "":
					OS.shell_open(url)
					_sfx("item")
				return
	for b in model.title_btns:
		if not MenuHelpers.in_btn(p, b):
			continue
		var id = str(b.get("id", ""))
		match id:
			"mode":
				GameState.difficulty = (GameState.difficulty + 1) % 3
				GameState.apply_difficulty()
				ProgressStore.progress["difficulty"] = GameState.difficulty
				ProgressStore.queue_save()
				_sfx("graze")
			"ngplus":
				ng_pressed.emit()
				GameState.set_state(GameState.State.NG_SELECT)
				_sfx("item")
			"lb":
				leaderboard_pressed.emit()
				GameState.set_state(GameState.State.LEADERBOARD)
				_sfx("item")
			"emblems":
				if MenuHelpers.emblem_count() >= 20:
					ProgressStore.unlock_emblem("bride")
				emblems_pressed.emit()
				GameState.set_state(GameState.State.EMBLEMS)
				_sfx("item")
			"arsenal":
				arsenal_pressed.emit()
				model.arsenal_return = "title"
				GameState.set_state(GameState.State.ARSENAL)
				_sfx("item")
			"outfit":
				outfits_pressed.emit()
				model.outfit_preview = GameState.selected_outfit
				GameState.set_state(GameState.State.OUTFITS)
				_sfx("item")
			"settings":
				settings_pressed.emit()
				GameState.set_state(GameState.State.SETTINGS)
				_sfx("item")
			"help":
				var help = get_tree().get_first_node_in_group("help_canvas")
				if help and help.has_method("open_help"):
					help.open_help()
				_sfx("item")
			"shoutouts":
				shoutouts_pressed.emit()
				P2Meta.open_shoutouts()
				_sfx("item")
			"start":
				_start()
			"login":
				_on_login_pressed()
		return
	_start()

func _handle_outfits(p: Vector2) -> void:
	if MenuHelpers.in_btn(p, model.outfit_pose_btn):
		model.outfit_pose = (model.outfit_pose + 1) % MenuHelpers.OUTFIT_POSES.size()
		model.outfit_anim_t = 0
		ProgressStore.progress["pose"] = model.outfit_pose
		ProgressStore.queue_save()
		_sfx("graze")
		return
	if MenuHelpers.in_btn(p, model.face_btn):
		model.victory_face = (model.victory_face + 1) % MenuHelpers.VICTORY_FACES.size()
		ProgressStore.progress["face"] = model.victory_face
		ProgressStore.queue_save()
		_sfx("graze")
		return
	if MenuHelpers.in_btn(p, model.outfit_back_btn):
		_return_title()
		return
	for t in model.outfit_tiles:
		if MenuHelpers.in_btn(p, t):
			model.outfit_preview = str(t.get("key"))
			if bool(t.get("unlocked")):
				GameState.selected_outfit = model.outfit_preview
				ProgressStore.progress["outfit"] = GameState.selected_outfit
				ProgressStore.queue_save()
				_sfx("item")
			else:
				_sfx("hit")
			return

func _handle_emblems(p: Vector2) -> void:
	if MenuHelpers.in_btn(p, model.em_prev_btn):
		if model.em_page > 0:
			model.em_page -= 1
			_sfx("item")
		return
	if MenuHelpers.in_btn(p, model.em_next_btn):
		if model.em_page < MenuHelpers.em_page_count() - 1:
			model.em_page += 1
			_sfx("item")
		return
	_return_title()

func _handle_ng(p: Vector2) -> void:
	if MenuHelpers.in_btn(p, model.ng_back_btn):
		_return_title()
		return
	for t in model.ng_tiles:
		if MenuHelpers.in_btn(p, t):
			if bool(t.get("unlocked")):
				GameState.ng_plus = int(t.get("lvl", 0))
				ProgressStore.progress["ngPlus"] = GameState.ng_plus
				ProgressStore.queue_save()
				_sfx("graze")
			else:
				_sfx("hit")
			return

func _handle_arsenal_down(p: Vector2) -> void:
	for t in model.arsenal_tiles:
		if not MenuHelpers.in_btn(p, t):
			continue
		if t.get("tab") != null:
			model.ars_tab = str(t.get("tab"))
			model.ars_drag = null
			_sfx("item")
			return
		if bool(t.get("emptySlot", false)):
			model.ars_drag = {"empty": true, "sx": p.x, "sy": p.y, "x": p.x, "y": p.y, "moved": false}
			return
		if bool(t.get("locked", false)):
			model.ars_msg = {"t": 120, "txt": "🔒 Locked — buy it at Honey Badger’s shop"}
			model.ars_drag = null
			_sfx("hit")
			return
		if t.get("key") != null:
			model.ars_drag = {
				"type": str(t.get("type", model.ars_tab)),
				"key": str(t.get("key")),
				"from": "hotbar" if bool(t.get("fromHot", false)) else "pool",
				"slot": t.get("hotbarSlot", -1),
				"sx": p.x, "sy": p.y, "x": p.x, "y": p.y, "moved": false,
			}
			return
	model.ars_drag = {"empty": true, "sx": p.x, "sy": p.y, "x": p.x, "y": p.y, "moved": false}

func _handle_arsenal_up(p: Vector2) -> void:
	var d = model.ars_drag
	model.ars_drag = null
	if d == null or typeof(d) != TYPE_DICTIONARY:
		return
	if bool(d.get("empty", false)):
		if not bool(d.get("moved", false)):
			_exit_arsenal()
		return
	var type = str(d.get("type", model.ars_tab))
	var key = str(d.get("key", ""))
	if key == "":
		return
	if not bool(d.get("moved", false)):
		# tap: toggle equip from pool, or unequip from hotbar
		if str(d.get("from")) == "hotbar":
			model.unequip_slot(type, int(d.get("slot", 0)))
			_sfx("item")
		else:
			if MenuHelpers.content_unlocked(type, key) or type == "i":
				model.toggle_equip(type, key)
			else:
				model.ars_msg = {"t": 120, "txt": "🔒 Locked — buy it at Honey Badger’s shop"}
				_sfx("hit")
		return
	# drag release → drop into hotbar slot
	for t in model.arsenal_tiles:
		if t.get("hotbarSlot") == null:
			continue
		if MenuHelpers.in_btn(p, t):
			if MenuHelpers.content_unlocked(type, key) or type == "i":
				model.drop_to_slot(type, key, int(t.get("hotbarSlot", 0)))
				_sfx("power")
			else:
				_sfx("hit")
			return
	# drag off → unequip if from hotbar
	if str(d.get("from")) == "hotbar":
		model.unequip_slot(type, int(d.get("slot", 0)))
		_sfx("item")

func _handle_lb(p: Vector2) -> void:
	if MenuHelpers.in_btn(p, model.lb_prev_btn):
		if model.lb_page > 0:
			model.set_lb_page(model.lb_page - 1)
			_sfx("item")
		return
	if MenuHelpers.in_btn(p, model.lb_next_btn):
		if model.lb_page < model.lb_page_count() - 1:
			model.set_lb_page(model.lb_page + 1)
			_sfx("item")
		return
	for r in model.lb_rows:
		if MenuHelpers.in_btn(p, r):
			var u = str(r.get("profileUrl", ""))
			if u != "":
				OS.shell_open(u)
			return
	_return_title()

func _exit_arsenal() -> void:
	if model.arsenal_return == "stageclear":
		GameState.set_state(GameState.State.STAGE_CLEAR)
	else:
		_return_title()

func _return_title() -> void:
	GameState.return_to_title()
	_sfx("item")

func _start() -> void:
	start_pressed.emit()
	_sfx("item")
	GameState.start_run()


const SHOUTOUTS := [
	{"url": "https://bobina.moe", "label": "🌐 bobina.moe", "sub": "Official site"},
	{"url": "https://x.com/itsvibekilla", "label": "𝕏 Vibekilla", "sub": "@itsvibekilla"},
	{"url": "https://x.com/bobina_council", "label": "𝕏 Bobina Council", "sub": "@bobina_council"},
	{"url": "https://x.com/bobocouncil", "label": "𝕏 Bobo Council", "sub": "@bobocouncil"},
	{"url": "https://x.com/emblemvault", "label": "𝕏 Emblem Vault", "sub": "@emblemvault"},
	{"url": "https://x.com/JungleBayAC", "label": "𝕏 Jungle Bay", "sub": "@JungleBayAC"},
	{"url": "https://x.com/monke_meme_eth", "label": "𝕏 Monke", "sub": "@monke_meme_eth"},
	{"url": "https://x.com/SKOL_ERC20", "label": "𝕏 SKOL", "sub": "@SKOL_ERC20"},
	{"url": "https://x.com/HBDCERC20", "label": "𝕏 Honey Badger", "sub": "@HBDCERC20"},
	{"url": "https://x.com/krakenfx", "label": "𝕏 Kraken", "sub": "@krakenfx"},
	{"url": "https://x.com/ourbit", "label": "𝕏 Ourbit", "sub": "@ourbit"},
	{"url": "https://picklecharts.com", "label": "🥒 PickleCharts", "sub": "picklecharts.com"},
]

var _shout_hits: Array = []
var _shout_close: Dictionary = {}

func _draw_shoutouts() -> void:
	_shout_hits.clear()
	var W = Config.W
	var H = Config.H
	ctx.fill_style("rgba(8,4,16,0.88)")
	ctx.fill_rect(0, 0, W, H)
	var pw = 420.0
	var ph = 420.0
	var px = W * 0.5 - pw * 0.5
	var py = H * 0.5 - ph * 0.5
	ctx.fill_style("rgba(28,14,40,0.96)")
	ctx.begin_path()
	ctx.round_rect(px, py, pw, ph, 14)
	ctx.fill()
	ctx.stroke_style("#ff9ecb")
	ctx.line_width(2)
	ctx.stroke()
	ctx.text_align("center")
	ctx.fill_style("#ffe08a")
	ctx.font("900 22px Trebuchet MS")
	ctx.fill_text("📣 SHOUTOUTS", W * 0.5, py + 36)
	ctx.fill_style("#c8b0d0")
	ctx.font("12px monospace")
	ctx.fill_text("Follow Bobina Council & friends on X", W * 0.5, py + 56)
	var y = py + 80
	for s in SHOUTOUTS:
		var row = {"x": px + 24, "y": y - 14, "w": pw - 48, "h": 30, "url": s["url"]}
		_shout_hits.append(row)
		ctx.fill_style("rgba(255,255,255,0.05)")
		ctx.begin_path()
		ctx.round_rect(row.x, row.y, row.w, row.h, 8)
		ctx.fill()
		ctx.fill_style("#ffd6ea")
		ctx.font("bold 13px Trebuchet MS")
		ctx.text_align("left")
		ctx.fill_text(s["label"], row.x + 12, y + 2)
		ctx.fill_style("#9a8ba8")
		ctx.font("11px monospace")
		ctx.text_align("right")
		ctx.fill_text(s["sub"], row.x + row.w - 12, y + 2)
		y += 34
	_shout_close = {"x": px + pw * 0.5 - 60, "y": py + ph - 44, "w": 120, "h": 28}
	ctx.fill_style("rgba(143,208,255,0.2)")
	ctx.begin_path()
	ctx.round_rect(_shout_close.x, _shout_close.y, _shout_close.w, _shout_close.h, 8)
	ctx.fill()
	ctx.stroke_style("#8fd0ff")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.text_align("center")
	ctx.fill_text("CLOSE", W * 0.5, _shout_close.y + 19)
	ctx.text_align("left")

func _sfx(t: String) -> void:
	if AudioBus:
		AudioBus.sfx(t)

func _on_login_pressed() -> void:
	login_pressed.emit()
	ApiClient.open_login()

# Legacy button handlers (VBox hidden)
func _on_start_pressed() -> void: _start()
func _on_mode_pressed() -> void:
	GameState.difficulty = (GameState.difficulty + 1) % 3
	GameState.apply_difficulty()
	queue_redraw()
func _on_ng_pressed() -> void: GameState.set_state(GameState.State.NG_SELECT)
func _on_leaderboard_pressed() -> void: GameState.set_state(GameState.State.LEADERBOARD)
func _on_settings_pressed() -> void: GameState.set_state(GameState.State.SETTINGS)
func _on_outfits_pressed() -> void: GameState.set_state(GameState.State.OUTFITS)
func _on_emblems_pressed() -> void: GameState.set_state(GameState.State.EMBLEMS)
func _on_arsenal_pressed() -> void: GameState.set_state(GameState.State.ARSENAL)
