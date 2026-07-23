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
	var map := {
		"shoot": "shoot", "swap": "swap_weapon", "special": "special",
		"cycle": "cycle_special", "melee": "melee", "meleeswap": "meleeswap",
		"item_switch": "item_switch", "item_use": "item_use", "interact": "interact", "bomb": "bomb",
	}
	var act := str(map.get(action, action))
	if not InputMap.has_action(act):
		# HTML DEFAULT_BINDS
		var defaults := {
			"shoot": "Z", "swap_weapon": "C", "special": "V", "cycle_special": "B",
			"melee": "SPACE", "meleeswap": "D", "bomb": "X", "item_switch": "A", "item_use": "Q", "interact": "E",
		}
		return str(defaults.get(act, act.to_upper()))
	for e in InputMap.action_get_events(act):
		if e is InputEventKey:
			return OS.get_keycode_string((e as InputEventKey).physical_keycode if (e as InputEventKey).physical_keycode else (e as InputEventKey).keycode)
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

static func wrap_text(ctx, text: String, x: float, y: float, max_w: float, line_h: float, max_lines: int = 4) -> void:
	var words := text.split(" ")
	var line := ""
	var ly := y
	var lines := 0
	for w in words:
		var trial := (line + " " + w).strip_edges()
		var tw: float = float(ctx.measure_text(trial).get("width", 0))
		if tw > max_w and line != "":
			ctx.fill_text(line, x, ly)
			ly += line_h
			lines += 1
			line = w
			if lines >= max_lines:
				return
		else:
			line = trial
	if line != "" and lines < max_lines:
		ctx.fill_text(line, x, ly)
