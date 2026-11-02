extends RefCounted
## Shared helpers for 1:1 HTML menu ports.

const ARS_CAP := {"w": 5, "s": 5, "m": 2, "i": 3}
const EM_PER_PAGE := 12
const LB_PER_PAGE := 10
const MAX_NG := 100

const OUTFIT_POSES := [
	{"name": "· Idle"},
	{"name": "♪ Dance"},
	{"name": "✦ Twirl"},
	{"name": "♥ Bounce"},
	{"name": ">v< Cheer"},
	{"name": "🔥 This Is Fine"},
]
const VICTORY_FACES := [
	{"name": "Auto", "expr": null},
	{"name": ":3", "expr": "uwu"},
	{"name": "Smile", "expr": "smile"},
	{"name": ">v<", "expr": "squee"},
	{"name": "Giggle", "expr": "giggle"},
	{"name": "Annoyed", "expr": "annoyed"},
]

static func fmt_score(n) -> String:
	var v := maxi(0, int(floor(float(n))))
	if v < 1000:
		return str(v)
	var units := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var u := 0
	var f := float(v)
	while f >= 1000.0 and u < units.size() - 1:
		f /= 1000.0
		u += 1
	var s: String
	if f >= 100.0:
		s = str(int(round(f)))
	elif f >= 10.0:
		s = "%.1f" % f
	else:
		s = "%.2f" % f
	if s.contains("."):
		s = s.rstrip("0").rstrip(".")
	return s + units[u]

static func kb(action: String) -> String:
	## Prefer keyboard label for HUD (compact); falls back to gamepad glyph
	var JoypadLabels = load("res://scripts/input/JoypadLabels.gd")
	var map := {
		"shoot": "shoot", "swap": "swap", "swap_weapon": "swap", "special": "special",
		"cycle": "cycle_special", "melee": "melee", "meleeswap": "meleeswap",
		"item_switch": "item_switch", "item_use": "item_use", "interact": "interact", "bomb": "bomb",
	}
	var act := str(map.get(action, action))
	if not InputMap.has_action(act):
		var defaults := {
			"shoot": "Z", "swap": "C", "special": "V", "cycle_special": "B",
			"melee": "SPACE", "meleeswap": "D", "bomb": "X", "item_switch": "A", "item_use": "Q", "interact": "E",
		}
		return str(defaults.get(act, act.to_upper()))
	for e in InputMap.action_get_events(act):
		if e is InputEventKey:
			if JoypadLabels:
				return JoypadLabels.event_label(e)
			var k := e as InputEventKey
			return OS.get_keycode_string(k.physical_keycode if k.physical_keycode else k.keycode)
	for e2 in InputMap.action_get_events(act):
		if e2 is InputEventJoypadButton or e2 is InputEventJoypadMotion:
			if JoypadLabels:
				return JoypadLabels.event_label(e2)
	return act.to_upper()

static func emblem_count() -> int:
	## HTML emblemCount
	return ProgressStore.emblem_count() if ProgressStore.has_method("emblem_count") else _emblem_count_fallback()

static func _emblem_count_fallback() -> int:
	var n := 0
	for k in ProgressStore.emblems.keys():
		if ProgressStore.emblems[k]:
			n += 1
	return n

static func em_page_count() -> int:
	return maxi(1, int(ceili(float(DataRegistry.emblems.size()) / float(EM_PER_PAGE))))

static func outfit_emoji(key: String) -> String:
	if DataRegistry.outfit_emoji.has(key):
		return str(DataRegistry.outfit_emoji[key])
	for o in DataRegistry.outfits:
		if str(o.get("key")) == key and o.has("emoji"):
			return str(o["emoji"])
	return "👗"

static func content_unlocked(type: String, key: String) -> bool:
	## HTML contentUnlocked — FREE + shopUnlocks + grandfather equipped w/s/m
	return ProgressStore.content_unlocked(type, key)

static func lock_cost(type: String, key: String) -> int:
	## HTML lockCost — FREE=0, SHOP_COST overrides, else CONTENT_COST
	return ProgressStore.lock_cost(type, key)

static func consum_qty(key: String) -> int:
	var c: Dictionary = ProgressStore.progress.get("consum", {})
	return int(c.get(key, 0))

static func reset_inventory() -> void:
	## HTML resetInventory
	ProgressStore.reset_inventory()

static func fill_bg(ctx, c0: String, c1: String, W: float, H: float) -> void:
	ctx.fill_style(c0)
	ctx.fill_rect(0, 0, W, H * 0.55)
	ctx.fill_style(c1)
	ctx.fill_rect(0, H * 0.45, W, H * 0.55)

static func in_btn(p: Vector2, b) -> bool:
	if b == null or typeof(b) != TYPE_DICTIONARY:
		return false
	var x := float(b.get("x", 0))
	var y := float(b.get("y", 0))
	var w := float(b.get("w", 0))
	var h := float(b.get("h", 0))
	return p.x >= x and p.x <= x + w and p.y >= y and p.y <= y + h

static func open_url(url: String, same_tab: bool = false) -> void:
	## Open external link. Web prefers window.open so this tab (and lofi) stays alive.
	## same_tab=true only for OAuth-style full navigation.
	if url == "":
		return
	if OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge"):
		var safe := url.replace("\\", "\\\\").replace("'", "\\'")
		if same_tab:
			JavaScriptBridge.eval("try{window.location.href='%s';}catch(e){}" % safe, true)
		else:
			JavaScriptBridge.eval("try{window.open('%s','_blank','noopener');}catch(e){}" % safe, true)
		return
	OS.shell_open(url)

static func wrap_text(ctx, text: String, x: float, y: float, max_w: float, line_h: float, max_lines: int = 4) -> void:
	## HTML wrapText — measure `line + word + " "` so the trailing space counts.
	var words := text.split(" ")
	var line := ""
	var ly := y
	var lines := 0
	for w in words:
		if str(w) == "":
			continue
		var trial := line + str(w) + " "
		var tw: float = float(ctx.measure_text(trial).get("width", 0))
		if tw > max_w and line != "":
			ctx.fill_text(line, x, ly)
			ly += line_h
			lines += 1
			line = str(w) + " "
			if lines >= max_lines:
				return
		else:
			line = trial
	if line != "" and lines < max_lines:
		ctx.fill_text(line, x, ly)

static func draw_galaxy_jar(ctx, s: float) -> void:
	## HTML CONSUMABLES galaxygas.draw — glass jar, not the emoji.
	## Caller translates to the icon anchor. s is the HTML draw() size (24 = 1:1).
	if ctx == null:
		return
	var u := float(s) / 24.0
	ctx.save()
	ctx.scale(u, u)
	ctx.save()
	ctx.begin_path()
	ctx.round_rect(-7, -6, 14, 15, 4)
	ctx.clip()
	var g = ctx.create_radial_gradient(-1, 3, 0.4, -1, 3, 10)
	g.add_color_stop(0, "#efe4ff")
	g.add_color_stop(0.32, "#9d6bff")
	g.add_color_stop(0.7, "#3a1a6a")
	g.add_color_stop(1, "#0a0618")
	ctx.fill_style(g)
	ctx.fill_rect(-8, -7, 16, 17)
	ctx.stroke_style("rgba(222,205,255,0.75)")
	ctx.line_width(0.7)
	for arm in range(2):
		ctx.begin_path()
		var first := true
		var t := 0.2
		while t < 3.2:
			var rr := t * 2.1
			var an := t * 1.5 + float(arm) * PI
			var x := -1.0 + cos(an) * rr
			var y := 3.0 + sin(an) * rr * 0.85
			if first:
				ctx.move_to(x, y)
				first = false
			else:
				ctx.line_to(x, y)
			t += 0.25
		ctx.stroke()
	ctx.fill_style("#fff")
	for st in [[-4.0, -2.0, 0.7], [3.0, 5.0, 0.6], [-3.0, 6.0, 0.5], [5.0, 1.0, 0.5], [1.0, -3.0, 0.6], [-5.0, 2.0, 0.5], [2.0, 2.0, 0.4]]:
		ctx.begin_path()
		ctx.arc(st[0], st[1], st[2], 0, TAU)
		ctx.fill()
	ctx.restore()
	ctx.stroke_style("rgba(200,225,255,0.6)")
	ctx.line_width(1)
	ctx.begin_path()
	ctx.round_rect(-7, -6, 14, 15, 4)
	ctx.stroke()
	ctx.stroke_style("rgba(255,255,255,0.55)")
	ctx.line_width(0.9)
	ctx.begin_path()
	ctx.move_to(-4.5, -3)
	ctx.line_to(-4.5, 5)
	ctx.stroke()
	ctx.fill_style("#cdb083")
	ctx.begin_path()
	ctx.round_rect(-8, -9.5, 16, 4, 1.6)
	ctx.fill()
	ctx.fill_style("#e6cfa2")
	ctx.begin_path()
	ctx.round_rect(-5, -11, 10, 2.4, 1)
	ctx.fill()
	ctx.restore()

static func h_esc(s: String) -> String:
	## HTML _hEsc — escape for HTML help builders (HelpCanvas is canvas-only; keep for parity)
	return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

static func any_modal_open() -> bool:
	## HTML anyModalOpen — settings / help / keybinds / display / shoutouts / name entry
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	if GameState and GameState.state == GameState.State.SETTINGS:
		return true
	# HelpCanvas: explicit `open` flag
	for n in tree.get_nodes_in_group("help_canvas"):
		if n and n.get("open") != null and bool(n.open):
			return true
	# Display / keybinds: visible Control overlays
	for group in ["display_menu", "keybinds_menu"]:
		for n in tree.get_nodes_in_group(group):
			if n is CanvasItem and (n as CanvasItem).visible:
				return true
	if P2Meta:
		if P2Meta.get("shoutouts_open") != null and bool(P2Meta.shoutouts_open):
			return true
		if P2Meta.get("name_entry_open") != null and bool(P2Meta.name_entry_open):
			return true
	return false
