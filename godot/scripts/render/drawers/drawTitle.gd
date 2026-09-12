extends RefCounted
## 1:1 port of HTML drawTitle + drawTitleBtn + drawMaidDance.
## Social strip matches HTML #social (desktop); touch hides strip (SHOUTOUTS modal).

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

## HTML #social links (exact labels/URLs)
const SOCIAL_LINKS := [
	{"url": "https://bobina.moe", "label": "🌐 bobina.moe"},
	{"url": "https://x.com/itsvibekilla", "label": "𝕏 Vibekilla"},
	{"url": "https://x.com/bobina_council", "label": "𝕏 Bobina Council"},
	{"url": "https://x.com/bobocouncil", "label": "𝕏 Bobo Council"},
	{"url": "https://x.com/emblemvault", "label": "𝕏 Emblem Vault"},
	{"url": "https://x.com/JungleBayAC", "label": "𝕏 Jungle Bay"},
	{"url": "https://x.com/monke_meme_eth", "label": "𝕏 Monke"},
	{"url": "https://x.com/SKOL_ERC20", "label": "𝕏 SKOL"},
	{"url": "https://x.com/HBDCERC20", "label": "𝕏 Honey Badger"},
	{"url": "https://x.com/krakenfx", "label": "𝕏 Kraken"},
	{"url": "https://x.com/ourbit", "label": "𝕏 Ourbit"},
	{"url": "https://picklecharts.com", "label": "🥒 PickleCharts"},
]

var ctx
var tick: int = 0
var selected_outfit: String = "og"
var title_btns: Array = []  # {x,y,w,h,id}
var social_hits: Array = []  # {x,y,w,h,url}
var title_idle_t: float = 0.0
var is_touch: bool = false
var difficulty: int = 0
var ng_plus: int = 0
var ng_unlocked: int = 0
var _bobina  # drawBobina module (optional)
var _bob_cache  # BobinaDrawCache — title mini blit (HTML pixels, no live 4k drawer)
var _W: float = 960.0
var _H: float = 540.0
var _bg_tex: Texture2D = null
var _bg_h: float = -1.0
var _social_layout: Dictionary = {}
var chrome_btns: Array = []
var _live_bob: Vector2 = Vector2.ZERO
var _live_bob_sc: float = 1.15
var _live_start_y: float = 400.0
var _live_bh: float = 28.0

func setup(c) -> void:
	ctx = c
	_W = Config.W
	_H = Config.H

func set_tick(t: int) -> void:
	tick = t

func set_outfit(o: String) -> void:
	selected_outfit = o

func set_bobina(b) -> void:
	_bobina = b

func set_bob_cache(c) -> void:
	_bob_cache = c

func set_menu_state(st: Dictionary) -> void:
	if st.has("outfit"):
		selected_outfit = str(st["outfit"])
	if st.has("tick"):
		tick = int(st["tick"])
	if st.has("title_idle_t"):
		title_idle_t = float(st["title_idle_t"])
	if st.has("is_touch"):
		is_touch = bool(st["is_touch"])
	if st.has("difficulty"):
		difficulty = int(st["difficulty"])
	if st.has("ng_plus"):
		ng_plus = int(st["ng_plus"])
	if st.has("ng_unlocked"):
		ng_unlocked = int(st["ng_unlocked"])

func _outfit_name(key: String) -> String:
	for o in DataRegistry.outfits:
		if str(o.get("key", "")) == key:
			return str(o.get("name", key))
	return key

func _emblem_count() -> int:
	var n := 0
	for k in ProgressStore.emblems.keys():
		if ProgressStore.emblems[k]:
			n += 1
	return n

func _emblem_total() -> int:
	return DataRegistry.emblems.size()

func _kb_shoot() -> String:
	## HTML kb('shoot') — use physical_keycode (project binds keycode=0)
	return MenuHelpers.kb("shoot")

func drawTitleBtn(x, y, w, h, label, color, id) -> void:
	## HTML drawTitleBtn — single-line label, no wrap (shrink font if wider than pad)
	title_btns.append({"x": float(x), "y": float(y), "w": float(w), "h": float(h), "id": str(id if id != null else "mode")})
	ctx.fill_style("rgba(20,10,28,0.7)")
	ctx.begin_path()
	ctx.round_rect(float(x), float(y), float(w), float(h), 8)
	ctx.fill()
	ctx.stroke_style(str(color))
	ctx.line_width(2)
	ctx.stroke()
	ctx.fill_style(str(color))
	var lbl := str(label)
	var fsz := 14
	ctx.font("bold %dpx Trebuchet MS" % fsz)
	var tw := float(ctx.measure_text(lbl).get("width", 0))
	var max_w := float(w) - 12.0
	while tw > max_w and fsz > 9:
		fsz -= 1
		ctx.font("bold %dpx Trebuchet MS" % fsz)
		tw = float(ctx.measure_text(lbl).get("width", 0))
	ctx.text_align("center")
	# Single-line only — never multi-line wrap inside button
	ctx.fill_text(lbl, float(x) + float(w) / 2.0, float(y) + float(h) / 2.0 + float(fsz) * 0.35)
	ctx.text_align("left")

func drawMenuBtn(cx, y) -> Dictionary:
	## HTML drawMenuBtn — returns menuBtn rect
	var w := 150.0
	var h := 28.0
	var x := float(cx) - w / 2.0
	var btn := {"x": x, "y": float(y), "w": w, "h": h}
	ctx.fill_style("rgba(30,16,40,0.85)")
	ctx.begin_path()
	ctx.round_rect(x, float(y), w, h, 8)
	ctx.fill()
	ctx.stroke_style("#8fd0ff")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.text_align("center")
	ctx.fill_text("⌂ MAIN MENU  [M]", float(cx), float(y) + 19.0)
	ctx.text_align("left")
	return btn

func _title_bg_tex(W: float, H: float) -> Texture2D:
	## 1px-wide vertical strip of the HTML title gradient, stretched to W×H.
	if _bg_tex != null and _bg_h == H:
		return _bg_tex
	var ih := maxi(1, int(H))
	var img := Image.create(1, ih, false, Image.FORMAT_RGBA8)
	var c0 := Color.html("#1a0e26")
	var c1 := Color.html("#3a1030")
	var c2 := Color.html("#12060c")
	var last := maxf(1.0, H - 1.0)
	for y in range(ih):
		var t := float(y) / last
		var col: Color
		if t <= 0.6:
			col = c0.lerp(c1, t / 0.6)
		else:
			col = c1.lerp(c2, (t - 0.6) / 0.4)
		img.set_pixel(0, y, col)
	_bg_tex = ImageTexture.create_from_image(img)
	_bg_h = H
	return _bg_tex

func drawTitle() -> void:
	drawTitleChrome()
	drawTitleLive()

func drawTitleChrome() -> void:
	## Static title (wordmark glow, buttons, hints, auth, social) — baked to a SubViewport.
	title_btns = []
	social_hits = []
	var W := _W
	var H := _H
	var bgtex := _title_bg_tex(W, H)
	if bgtex != null and ctx.has_method("draw_image"):
		ctx.draw_image(bgtex, 0, 0, W, H)
	else:
		var bg = ctx.create_linear_gradient(0, 0, 0, H)
		bg.addColorStop(0, "#1a0e26")
		bg.addColorStop(0.6, "#3a1030")
		bg.addColorStop(1, "#12060c")
		ctx.fill_style(bg)
		ctx.fill_rect(0, 0, W, H)
	# Peephole portrait — HTML: clip circle then drawImage + gold stroke
	var S := 146.0
	var py0 := 20.0
	var img = null
	if AssetBank:
		img = AssetBank.get_tex("peephole")
	if img != null:
		ctx.save()
		if ctx.has_method("clip_circle"):
			ctx.clip_circle(W / 2.0, py0 + S / 2.0, S / 2.0)
		else:
			ctx.begin_path()
			ctx.arc(W / 2.0, py0 + S / 2.0, S / 2.0, 0, TAU)
			ctx.clip()
		ctx.draw_image(img, W / 2.0 - S / 2.0, py0, S, S)
		ctx.restore()
		ctx.stroke_style("#ffd27a")
		ctx.line_width(4)
		ctx.begin_path()
		ctx.arc(W / 2.0, py0 + S / 2.0, S / 2.0, 0, TAU)
		ctx.stroke()
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#ff2b6e")
	ctx.shadow_blur(22)
	ctx.fill_style("#ff5b8d")
	ctx.font("900 48px Trebuchet MS")
	ctx.line_width(6)
	ctx.stroke_style("#ffd27a")
	ctx.stroke_text("BOBINA", W / 2.0, 210)
	ctx.fill_text("BOBINA", W / 2.0, 210)
	ctx.font("900 36px Trebuchet MS")
	ctx.shadow_color("#ff5b3c")
	ctx.stroke_text("KILL ALL MUMUS!!", W / 2.0, 246)
	ctx.fill_style("#ffe08a")
	ctx.fill_text("KILL ALL MUMUS!!", W / 2.0, 246)
	ctx.restore()
	ctx.fill_style("#ffb3d4")
	ctx.font("italic 13px Trebuchet MS")
	ctx.fill_text("Rescue her dad Bobo from the evil clutches of the LA Cabal!", W / 2.0, 270)
	ctx.fill_style("#9a8ba8")
	ctx.font("11px Trebuchet MS")
	ctx.fill_text("A Touhou-Style Adventure • Created by the Bobina Council • Powered by Emblem Vault", W / 2.0, 286)
	# ---- menu buttons ----
	var bh := 34.0 if is_touch else 28.0
	var oW := 236.0 if is_touch else 200.0
	var oy := 298.0 if is_touch else 304.0
	var ox := W / 2.0 - oW / 2.0
	if not ProgressStore.outfit_unlocked(selected_outfit):
		selected_outfit = "og"
		GameState.selected_outfit = "og"
	_live_bob = Vector2(ox - 26.0, oy + bh / 2.0)
	_live_bob_sc = 1.15
	_live_bh = bh
	drawTitleBtn(ox, oy, oW, bh, "👗 OUTFIT: " + _outfit_name(selected_outfit) + "  ▸", "#ff9ecb", "outfit")
	var mW := 250.0 if is_touch else 232.0
	var lW := 150.0 if is_touch else 126.0
	var gap := 10.0
	var rowW := mW + gap + lW
	var rx := W / 2.0 - rowW / 2.0
	var ry := oy + bh + (10.0 if is_touch else 12.0)
	var mode_lbls := ["MODE: NORMAL (tap)", "MODE: HARD  🔥", "MODE: HELL  ☠"]
	var mode_cols := ["#8fd0ff", "#ff5b6e", "#ff2a2a"]
	var di := clampi(difficulty, 0, 2)
	drawTitleBtn(rx, ry, mW, bh, mode_lbls[di], mode_cols[di], "mode")
	drawTitleBtn(rx + mW + gap, ry, lW, bh, "🏆 LEADERBOARD", "#ffd27a", "lb")
	var ny := ry + bh + (10.0 if is_touch else 12.0)
	# HTML row3: ARSENAL · EMBLEMS · SETTINGS (+ NG+ if unlocked) (+ SHOUTOUTS on touch)
	# No HELP here — HTML keeps help in top chrome / settings, not this row
	var row3: Array = [
		{"l": "🎒 ARSENAL", "c": "#7fdfff", "id": "arsenal"},
		{"l": "🏅 EMBLEMS %d/%d" % [_emblem_count(), _emblem_total()], "c": "#ffd27a", "id": "emblems"},
		{"l": "⚙ SETTINGS", "c": "#b0a0d8", "id": "settings"},
	]
	if ng_unlocked > 0:
		var ng_l := ("🔁 NG+ Lv%d" % ng_plus) if ng_plus > 0 else "🔁 NG+ OFF"
		var ng_c := "#ffd27a" if ng_plus > 0 else "#8a7a92"
		row3.append({"l": ng_l, "c": ng_c, "id": "ngplus"})
	if is_touch:
		row3.append({"l": "📣 SHOUTOUTS", "c": "#8fd0a0", "id": "shoutouts"})
	# Fit single row within 960 — never wrap buttons to a second line
	var bw := 150.0
	var nbtn := float(row3.size())
	var tot := nbtn * bw + maxf(0.0, nbtn - 1.0) * gap
	var max_row := W - 24.0
	if tot > max_row and nbtn > 0.0:
		bw = (max_row - maxf(0.0, nbtn - 1.0) * gap) / nbtn
		tot = max_row
	var sx0 := W / 2.0 - tot / 2.0
	for i in range(row3.size()):
		var r: Dictionary = row3[i]
		drawTitleBtn(sx0 + float(i) * (bw + gap), ny, bw, bh, r["l"], r["c"], r["id"])
	ny += bh
	ctx.text_align("center")
	_live_start_y = ny + (12.0 if is_touch else 16.0)
	var pill_h := 34.0 if is_touch else 32.0
	ny = _live_start_y + pill_h + (10.0 if is_touch else 12.0)
	# HTML DOM overlays hint lines; do not shove copy up to make room for auth.
	var info_gap := 14.0 if not is_touch else 13.0
	if not is_touch:
		ctx.fill_style("#7a6a82")
		ctx.font("11px monospace")
		ctx.fill_text("Move: mouse/arrows · HOLD Z fire · SPACE melee (hold=charge) · D switch · SHIFT focus (2× = dash) · full-charge+dash = SLASH DASH · X bomb", W / 2.0, ny)
		ny += info_gap
		ctx.fill_style("#6a5a72")
		var ns := DataRegistry.stages.size()
		ctx.fill_text("%d stages · %d meme bosses · power fades, grab P · save your score globally" % [ns, ns], W / 2.0, ny)
		ny += info_gap
		ctx.fill_style("#8a6a92")
		ctx.fill_text("A Bobina Council LLC & Grr Finance production", W / 2.0, ny)
	else:
		ctx.fill_style("#a894b2")
		ctx.font("bold 11px monospace")
		ctx.fill_text("◀ JOYSTICK (bottom-left) moves — she auto-fires", W / 2.0, ny)
		ny += info_gap
		ctx.fill_style("#9a8aa2")
		ctx.font("11px monospace")
		ctx.fill_text("Buttons ▶  FOCUS · BOMB · SPEC (tap USE! when charged) · SWAP", W / 2.0, ny)
		ny += info_gap
		ctx.fill_style("#8a6a92")
		ctx.font("10px monospace")
		ctx.fill_text("A Bobina Council LLC & Grr Finance production · tap ⛶ for fullscreen", W / 2.0, ny)
	ctx.text_align("left")
	# HTML #bobinaAuth — centered pill above social (drawn on canvas for 1:1)
	_draw_auth_chrome(W, H)
	# HTML #social — desktop bottom strip (touch: hidden, lives in SHOUTOUTS)
	if not is_touch:
		_draw_social_bar(W, H)
	chrome_btns = title_btns.duplicate()

func drawTitleLive() -> void:
	## Particles, mini Bobina, blinking start pill — cheap, runs every title frame.
	title_btns = chrome_btns.duplicate()
	var W := _W
	var H := _H
	var cols := ["#ff6ec7", "#ffd27a", "#8fd0ff"]
	var use_circ: bool = ctx.has_method("fill_circle")
	ctx.global_alpha(0.5)
	for ci in range(3):
		ctx.fill_style(cols[ci])
		for i in range(ci, 40, 3):
			var a := float(tick) * 0.01 + float(i)
			var x := W / 2.0 + cos(a) * (120.0 + float(i) * 7.0)
			var y := 140.0 + sin(a * 1.3) * 80.0 + float(i) * 3.0
			var px := fposmod(x, W)
			var py := fposmod(y, H)
			if use_circ:
				ctx.fill_circle(px, py, 3)
			else:
				ctx.begin_path()
				ctx.arc(px, py, 3, 0, TAU)
				ctx.fill()
	ctx.global_alpha(1.0)
	_blit_title_bobina(_live_bob.x, _live_bob.y, _live_bob_sc)
	var st_txt: String
	if is_touch:
		st_txt = "▶  TAP TO START  ◀"
	else:
		var k := _kb_shoot()
		if k.strip_edges() == "" or k == "None" or k == "Unknown":
			k = "Z"
		st_txt = "▶  PRESS " + k + "   /   TAP TO START  ◀"
	ctx.text_align("center")
	ctx.font("bold %dpx monospace" % (22 if is_touch else 20))
	var stw: float = float(ctx.measure_text(st_txt).get("width", 280))
	var pad := 20.0
	var pill_h := 34.0 if is_touch else 32.0
	var ny := _live_start_y
	ctx.fill_style("rgba(255,90,140,0.14)")
	ctx.stroke_style("rgba(255,120,190,0.4)")
	ctx.line_width(1.5)
	ctx.begin_path()
	ctx.round_rect(W / 2.0 - stw / 2.0 - pad, ny, stw + pad * 2.0, pill_h, 10)
	ctx.fill()
	ctx.stroke()
	title_btns.append({
		"x": W / 2.0 - stw / 2.0 - pad,
		"y": ny,
		"w": stw + pad * 2.0,
		"h": pill_h,
		"id": "start",
	})
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 30.0)) % 2) != 0 else "#ffb3d4")
	ctx.fill_text(st_txt, W / 2.0, ny + pill_h / 2.0 + 7.0)
	ctx.text_align("left")
	if title_idle_t > 1800.0:
		drawMaidDance()

func _blit_title_bobina(cx: float, cy: float, sc: float) -> void:
	## HTML drawBobina at (ox-26, oy+bh/2) scale 1.15 — bake, don't run the 4k drawer live.
	var st := {
		"x": 0, "y": 0, "iframe": 0, "focus": false, "walk": 0, "bombFx": 0,
		"face": -PI / 2.0, "vx": 0, "vy": 0, "outfit": selected_outfit, "tick": tick,
	}
	if _bob_cache and _bob_cache.has_method("get_texture"):
		var tex: Texture2D = _bob_cache.get_texture(selected_outfit, null, 0, tick, sc, st)
		if tex != null and ctx.has_method("draw_image"):
			var tw := float(tex.get_width())
			var th := float(tex.get_height())
			ctx.draw_image(tex, cx - tw * 0.5, cy - th * 0.5, tw, th)
			return
	if _bobina == null:
		return
	ctx.save()
	ctx.translate(cx, cy)
	ctx.scale(sc, sc)
	_bobina.set_outfit(selected_outfit)
	_bobina.set_tick(tick)
	_bobina.drawBobina(st)
	if ctx.has_method("clear_shadow"):
		ctx.clear_shadow()
	ctx.restore()

func _draw_auth_chrome(W: float, H: float) -> void:
	## HTML #bobinaAuth — guest is a single pink pill (no caption). Signed-in is .who chip.
	var force_guest := GameState and GameState.has_meta("dual_mode") and bool(GameState.get_meta("dual_mode"))
	var logged := false
	var who := ""
	if not force_guest and ApiClient and ApiClient.authenticated:
		logged = true
		who = "Signed in as @%s" % str(ApiClient.me.get("username", "Bobina"))
	var label := "Cloud sync ready" if logged else "Sign in with Bobina"
	ctx.font("bold 13px Trebuchet MS")
	var tw := float(ctx.measure_text(label).get("width", 140))
	var btn_w := tw + 32.0
	var btn_h := 34.0
	# HTML #bobinaAuth { bottom: 52px } — bottom edge of the pill, above #social
	var by := H - (10.0 if is_touch else 52.0) - btn_h
	var bx := W / 2.0 - btn_w / 2.0
	title_btns.append({"x": bx, "y": by, "w": btn_w, "h": btn_h, "id": "login"})
	if logged:
		ctx.fill_style("rgba(20,8,16,0.88)")
		ctx.stroke_style("#ff7ab5")
		ctx.line_width(1.0)
		ctx.begin_path()
		ctx.round_rect(bx, by, btn_w, btn_h, 999)
		ctx.fill()
		ctx.stroke()
	else:
		# HTML: linear-gradient(180deg,#ff5b8d,#c42a5c); border:0; box-shadow:0 2px 10px rgba(0,0,0,.4)
		if ctx.has_method("shadow_color"):
			ctx.shadow_color("rgba(0,0,0,0.4)")
			ctx.shadow_blur(10)
		var g = ctx.create_linear_gradient(bx, by, bx, by + btn_h)
		g.addColorStop(0, "#ff5b8d")
		g.addColorStop(1, "#c42a5c")
		ctx.fill_style(g)
		ctx.begin_path()
		ctx.round_rect(bx, by, btn_w, btn_h, 999)
		ctx.fill()
		if ctx.has_method("clear_shadow"):
			ctx.clear_shadow()
	ctx.text_align("center")
	ctx.fill_style("#fff" if not logged else "#ffd0e4")
	ctx.font("bold 13px Trebuchet MS")
	ctx.fill_text(label, W / 2.0, by + btn_h / 2.0 + 4.5)
	if logged and who != "":
		ctx.fill_style("#ffd0e4")
		ctx.font("11px Trebuchet MS")
		ctx.fill_text(who, W / 2.0, by - 6.0)
	ctx.text_align("left")

func _draw_social_bar(W: float, H: float) -> void:
	## HTML #social { flex-wrap; gap:7px; padding:0 10px; bottom:6px; font 11 / padding 5px 9px }
	social_hits = []
	var gap := 7.0
	var pad_x := 9.0
	var h := 21.0
	var font_px := 11
	ctx.font("%dpx Trebuchet MS" % font_px)
	if _social_layout.get("W") != W or _social_layout.is_empty():
		var chips: Array = []
		for s in SOCIAL_LINKS:
			var lab := str(s["label"])
			var tw := float(ctx.measure_text(lab).get("width", 60))
			# HTML letter-spacing:.3px; Godot emoji advance is a bit narrower than HTML 𝕏
			tw += 0.3 * maxf(0.0, float(lab.length() - 1)) + 6.0
			chips.append({"s": s, "w": tw + pad_x * 2.0})
		var max_row := W - 20.0
		var rows: Array = []
		var cur: Array = []
		var row_w := 0.0
		for c in chips:
			var cw: float = float(c["w"])
			if cur.size() > 0 and row_w + gap + cw > max_row:
				rows.append({"items": cur, "w": row_w})
				cur = []
				row_w = 0.0
			if cur.size() > 0:
				row_w += gap
			row_w += cw
			cur.append(c)
		if cur.size() > 0:
			rows.append({"items": cur, "w": row_w})
		_social_layout = {"W": W, "h": h, "gap": gap, "rows": rows}
	var rows_c: Array = _social_layout.get("rows", [])
	var y := H - 6.0 - h
	for ri in range(rows_c.size() - 1, -1, -1):
		var row: Dictionary = rows_c[ri]
		var items: Array = row["items"]
		var x := W / 2.0 - float(row["w"]) / 2.0
		for c in items:
			var s: Dictionary = c["s"]
			var w: float = float(c["w"])
			social_hits.append({"x": x, "y": y, "w": w, "h": h, "url": str(s["url"])})
			ctx.fill_style("rgba(28,16,38,0.72)")
			ctx.begin_path()
			ctx.round_rect(x, y, w, h, 8)
			ctx.fill()
			ctx.stroke_style("rgba(255,120,190,0.28)")
			ctx.line_width(1)
			ctx.stroke()
			ctx.fill_style("#c8b0d0")
			ctx.font("%dpx Trebuchet MS" % font_px)
			ctx.text_align("center")
			ctx.fill_text(str(s["label"]), x + w / 2.0, y + h / 2.0 + 3.5)
			ctx.text_align("left")
			x += w + gap
		y -= h + gap


func drawMaidDance() -> void:
	## HTML: idle 30s on title → maid-dance easter egg (full drawBobina)
	if ProgressStore.has_method("unlock_emblem"):
		ProgressStore.unlock_emblem("afk_dance")
	var t := float(tick)
	var W := _W
	var H := _H
	ctx.save()
	ctx.fill_style("rgba(8,4,14,0.86)")
	ctx.fill_rect(0, 0, W, H)
	# spotlight cone (approx without radial gradient)
	ctx.fill_style("rgba(255,180,230,0.18)")
	ctx.begin_path()
	ctx.move_to(W / 2.0 - 60.0, 110.0)
	ctx.line_to(W / 2.0 + 60.0, 110.0)
	ctx.line_to(W / 2.0 + 200.0, H - 40.0)
	ctx.line_to(W / 2.0 - 200.0, H - 40.0)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style("rgba(255,120,190,0.14)")
	ctx.begin_path()
	ctx.ellipse(W / 2.0, 360.0, 130.0, 26.0, 0, 0, TAU)
	ctx.fill()
	ctx.text_align("center")
	var notes := ["♪", "♫", "♥", "✦", "♬"]
	var ncols := ["#ff9ecb", "#ffd27a", "#8fd0ff", "#b8f08a"]
	for i in range(10):
		var base := t * 0.7 + float(i) * 70.0
		var ny := 110.0 + fposmod(H - 160.0 - fposmod(base, H - 160.0), H - 160.0)
		# simpler bobbing notes
		ny = 110.0 + fposmod(base, H - 160.0)
		var nx := W / 2.0 + sin(t * 0.03 + float(i) * 1.3) * (90.0 + float(i) * 13.0)
		ctx.global_alpha(0.5 + 0.3 * sin(t * 0.1 + float(i)))
		ctx.fill_style(ncols[i % 4])
		ctx.font("bold %dpx monospace" % (18 + (i % 3) * 4))
		ctx.fill_text(notes[i % 5], nx, ny)
	ctx.global_alpha(1.0)
	var bounce := absf(sin(t * 0.15)) * 11.0
	var sway := sin(t * 0.11) * 16.0
	var tilt := sin(t * 0.11) * 0.13
	if _bobina:
		ctx.save()
		ctx.translate(W / 2.0 + sway, 340.0 - bounce)
		ctx.rotate(tilt)
		ctx.scale(4.6, 4.6)
		_bobina.set_outfit(selected_outfit)
		_bobina.set_tick(tick)
		_bobina.drawBobina({
			"x": 0, "y": 0, "iframe": 0, "focus": false, "walk": 0, "bombFx": 0,
			"face": -PI / 2.0,
			"vx": sin(t * 0.3) * 3.6,
			"vy": cos(t * 0.42) * 1.6,
			"lean": sin(t * 0.11) * 0.5,
			"outfit": selected_outfit,
			"expr": "uwu",
			"tick": tick,
		})
		ctx.restore()
	ctx.fill_style("#fff" if (int(floorf(t / 24.0)) % 2) != 0 else "#ff9ecb")
	ctx.font("900 27px Trebuchet MS")
	ctx.shadow_color("#ff2b6e")
	ctx.shadow_blur(14)
	ctx.fill_text("♪  Don’t mind me… waiting for you to play!  ♪", W / 2.0, H - 34.0)
	ctx.shadow_blur(0)
	ctx.fill_style("#c8b0d0")
	ctx.font("13px monospace")
	ctx.fill_text("— tap / press any key to start —", W / 2.0, 96.0)
	ctx.text_align("left")
	ctx.restore()
