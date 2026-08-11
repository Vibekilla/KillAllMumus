extends Node
## Consumables: cycle with item_switch, TAP item_use to consume (+ 3s CD, no hold).

var selected: int = 0
## Cooldown in frames @ 60 Hz (HTML player._eCd). Hold progress vars retired.
var e_cd: float = 0.0
var e_t: float = 0.0  # unused — kept for HUD dual safety
var e_held: bool = false  # unused
var e_used: bool = false  # unused

const COOLDOWN_FRAMES := 180.0  # 3s

func inventory() -> Dictionary:
	## Always a mutable Dictionary — cloud/localStorage can leave Array/null.
	var raw = ProgressStore.progress.get("consum", {}) if ProgressStore and ProgressStore.progress is Dictionary else {}
	if typeof(raw) != TYPE_DICTIONARY:
		var fixed: Dictionary = {}
		ProgressStore.progress["consum"] = fixed
		return fixed
	return raw as Dictionary

func arsenal_i() -> Array:
	## HTML arsenalI — equipped item slots (may include 0-qty keys)
	var raw = ProgressStore.progress.get("arsenal", {}) if ProgressStore and ProgressStore.progress is Dictionary else {}
	if typeof(raw) != TYPE_DICTIONARY:
		return []
	var a = (raw as Dictionary).get("i", [])
	return a.duplicate() if a is Array else []

func keys() -> Array:
	## equipped slots (HTML arsenalI), not just positive-qty keys
	return arsenal_i()

func qty(key: String) -> int:
	var inv := inventory()
	if not inv.has(key):
		return 0
	return int(inv[key])

func consum_by_id(key: String) -> Dictionary:
	for c in DataRegistry.consumables:
		if str(c.get("key", "")) == key:
			return c
	return {}

func sel_consum_obj() -> Dictionary:
	## HTML selConsumObj
	var ai := arsenal_i()
	if ai.is_empty():
		return {}
	if selected >= ai.size():
		selected = 0
	return consum_by_id(str(ai[selected]))

func cycle() -> void:
	## HTML cycleConsumable
	var ai := arsenal_i()
	if ai.is_empty():
		if AudioBus:
			AudioBus.sfx("hit")
		CombatHelpers.flash("No items equipped — set them in the Arsenal", 75.0)
		return
	selected = (selected + 1) % ai.size()
	var c := sel_consum_obj()
	if not c.is_empty():
		if AudioBus:
			AudioBus.sfx("item")
		var k := str(c.get("key", ""))
		CombatHelpers.flash("%s %s  ×%d" % [str(c.get("icon", "•")), str(c.get("name", k)), qty(k)], 75.0)

func selected_key() -> String:
	var c := sel_consum_obj()
	return str(c.get("key", ""))

func is_full(key: String) -> bool:
	## HTML CONSUMABLES[i].full() — skip waste when already maxed
	match key:
		"honeycomb", "wagyu":
			return GameState.lives >= CombatHelpers.MAX_LIVES
		"bulltears", "bullsouls", "galaxygas":
			return GameState.power >= CombatHelpers.power_cap()
		"clover":
			return GameState.special_meter >= 100.0
		_:
			return false

func use_selected() -> bool:
	## HTML consumeSelected
	return consume_selected()

func consume_selected() -> bool:
	## HTML consumeSelected — also works in STAGE_CLEAR prep (stock/heal before portal).
	var c := sel_consum_obj()
	if c.is_empty():
		return false
	if GameState.state != GameState.State.PLAY and GameState.state != GameState.State.STAGE_CLEAR:
		return false
	var tree := get_tree()
	var player = tree.get_first_node_in_group("player") if tree else null
	if player == null or not is_instance_valid(player):
		return false
	var k := str(c.get("key", ""))
	if k.is_empty():
		return false
	if qty(k) > 0:
		if is_full(k):
			if AudioBus:
				AudioBus.sfx("hit")
			if CombatHelpers:
				CombatHelpers.flash("Already maxed — %s saved" % str(c.get("name", k)), 80.0)
				CombatHelpers.pop(player.global_position.x, player.global_position.y - 30.0, "FULL", "#9fe0a4")
			return false
		var inv := inventory()
		var left := qty(k) - 1
		if left <= 0:
			inv.erase(k)
		else:
			inv[k] = left
		if ProgressStore and ProgressStore.progress is Dictionary:
			ProgressStore.progress["consum"] = inv
			ProgressStore.save_consum()
		_apply_effect(k, player)
		if AudioBus:
			AudioBus.sfx("extend")
		var col := str(c.get("color", c.get("col", "#ffcf5a")))
		if CombatHelpers:
			CombatHelpers.flash("%s %s used!" % [str(c.get("icon", "•")), str(c.get("name", k))], 90.0)
			CombatHelpers.pop(player.global_position.x, player.global_position.y - 30.0, str(c.get("icon", "•")), col)
			for i in range(14):
				CombatHelpers.particles.append({
					"x": player.global_position.x,
					"y": player.global_position.y,
					"vx": (randf() - 0.5) * 6.0,
					"vy": (randf() - 0.5) * 6.0,
					"life": 26.0,
					"c": col,
				})
		if k == "honeycomb" and ProgressStore:
			ProgressStore.estats_add("honeycombs", 1)
			if int(ProgressStore.estats.get("honeycombs", 0)) >= 100:
				ProgressStore.unlock_emblem("honeycomb_100")
		return true
	else:
		if AudioBus:
			AudioBus.sfx("hit")
		if CombatHelpers:
			CombatHelpers.flash("No %s left — buy some at the shop" % str(c.get("name", k)), 70.0)
		return false

func tick(delta: float) -> void:
	## Tap item_use once to consume (3s cooldown). Works in cleared prep too.
	if GameState.state != GameState.State.PLAY and GameState.state != GameState.State.STAGE_CLEAR:
		return
	var df := delta * 60.0
	if e_cd > 0.0:
		e_cd = maxf(0.0, e_cd - df)
	e_held = false
	e_t = 0.0
	e_used = false
	if Input.is_action_just_pressed("item_use"):
		if e_cd > 0.0:
			if AudioBus:
				AudioBus.sfx("hit")
			CombatHelpers.flash("⌛ Item cooling down — %ds" % int(ceili(e_cd / 60.0)), 60.0)
		elif consume_selected():
			e_cd = COOLDOWN_FRAMES

func _apply_effect(key: String, p: Node = null) -> void:
	## HTML CONSUMABLES[i].apply()
	if p == null or not is_instance_valid(p):
		var tree := get_tree()
		p = tree.get_first_node_in_group("player") if tree else null
	var cap := 6.0
	if CombatHelpers and CombatHelpers.has_method("power_cap"):
		cap = CombatHelpers.power_cap()
	match key:
		"honeycomb":
			# HTML: run.lives=Math.min(MAX_LIVES, lives+1) — not gainLife (which awards 50k at cap)
			var max_l := CombatHelpers.MAX_LIVES if CombatHelpers else 9
			GameState.lives = mini(max_l, GameState.lives + 1)
		"wagyu":
			# HTML: +3 hearts clamped — never converts overflow to score
			var max_w := CombatHelpers.MAX_LIVES if CombatHelpers else 9
			GameState.lives = mini(max_w, GameState.lives + 3)
		"bulltears":
			# HTML: power +0.5 toward cap
			GameState.power = minf(cap, GameState.power + 0.5)
		"bullsouls":
			GameState.power = minf(cap, GameState.power + 1.5)
		"galaxygas":
			GameState.power = minf(cap, GameState.power + 3.75)
		"clover":
			GameState.special_meter = minf(100.0, GameState.special_meter + 25.0)
		"stardust":
			if ItemSystem and ItemSystem.has_method("spawn_stardust"):
				ItemSystem.spawn_stardust()
		"bubbles":
			if ItemSystem and ItemSystem.has_method("spawn_bubbles"):
				ItemSystem.spawn_bubbles()
		"banana":
			if p and is_instance_valid(p):
				if "rapid_t" in p:
					p.rapid_t = maxf(float(p.rapid_t), 330.0)
				else:
					p.set("rapid_t", 330.0)
			if CombatHelpers:
				CombatHelpers.flash("🍌 MONKE'S FRENZY!", 80.0)
			if AudioBus:
				AudioBus.sfx("power")
		"vial", "unholy":
			# HTML Unholy Vial: vialHits=3, vialT=300 (not shieldT)
			if p and is_instance_valid(p):
				if "vial_hits" in p:
					p.vial_hits = 3
				else:
					p.set("vial_hits", 3)
				if "vial_t" in p:
					p.vial_t = 300.0
				else:
					p.set("vial_t", 300.0)
			if CombatHelpers:
				CombatHelpers.flash("🧪 UNHOLY VIAL — VOID WARD!", 80.0)
			if AudioBus:
				AudioBus.sfx("power")
		"wormhole":
			# HTML: player.phaseT=180; sfx('warp'); screenShake=5
			if p and is_instance_valid(p):
				if "phase_t" in p:
					p.phase_t = maxf(float(p.phase_t), 180.0)
				else:
					p.set("phase_t", 180.0)
			if CombatHelpers:
				CombatHelpers.flash("🌀 WORMHOLE — PHASED!", 80.0)
				CombatHelpers.screen_shake = maxf(CombatHelpers.screen_shake, 5.0)
			if AudioBus:
				AudioBus.sfx("warp")
		_:
			GameState.special_meter = minf(100.0, GameState.special_meter + 40.0)
