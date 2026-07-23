extends Node
## HTML consumables: cycle with item_switch, hold item_use 0.8s to consume (+ 3s CD).

var selected: int = 0
## HTML player._eCd / _eT / _eHeld / _eUsed (frame units @ 60 Hz)
var e_cd: float = 0.0
var e_t: float = 0.0
var e_held: bool = false
var e_used: bool = false

const HOLD_FRAMES := 48.0   # 0.8s
const COOLDOWN_FRAMES := 180.0  # 3s

func inventory() -> Dictionary:
	return ProgressStore.progress.get("consum", {})

func arsenal_i() -> Array:
	## HTML arsenalI — equipped item slots (may include 0-qty keys)
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	var a = ar.get("i", [])
	return a.duplicate() if a is Array else []

func keys() -> Array:
	## equipped slots (HTML arsenalI), not just positive-qty keys
	return arsenal_i()

func qty(key: String) -> int:
	return int(inventory().get(key, 0))

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
	## HTML consumeSelected
	var c := sel_consum_obj()
	if c.is_empty() or GameState.state != GameState.State.PLAY:
		return false
	var player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if player == null:
		return false
	var k := str(c.get("key", ""))
	if qty(k) > 0:
		if is_full(k):
			if AudioBus:
				AudioBus.sfx("hit")
			CombatHelpers.flash("Already maxed — %s saved" % str(c.get("name", k)), 80.0)
			CombatHelpers.pop(player.global_position.x, player.global_position.y - 30.0, "FULL", "#9fe0a4")
			return false
		var inv := inventory()
		inv[k] = qty(k) - 1
		if int(inv[k]) <= 0:
			inv.erase(k)
		ProgressStore.progress["consum"] = inv
		ProgressStore.save_consum()
		_apply_effect(k, player)
		if AudioBus:
			AudioBus.sfx("extend")
		CombatHelpers.flash("%s %s used!" % [str(c.get("icon", "•")), str(c.get("name", k))], 90.0)
		CombatHelpers.pop(player.global_position.x, player.global_position.y - 30.0, str(c.get("icon", "•")), str(c.get("color", c.get("col", "#fff"))))
		# spark particles
		var col := str(c.get("color", c.get("col", "#ffcf5a")))
		for i in range(14):
			CombatHelpers.particles.append({
				"x": player.global_position.x,
				"y": player.global_position.y,
				"vx": (randf() - 0.5) * 6.0,
				"vy": (randf() - 0.5) * 6.0,
				"life": 26.0,
				"c": col,
			})
		if k == "honeycomb":
			ProgressStore.estats_add("honeycombs", 1)
			if int(ProgressStore.estats.get("honeycombs", 0)) >= 100:
				ProgressStore.unlock_emblem("honeycomb_100")
		return true
	else:
		if AudioBus:
			AudioBus.sfx("hit")
		CombatHelpers.flash("No %s left — buy some at the shop" % str(c.get("name", k)), 70.0)
		return false

func tick(delta: float) -> void:
	## HTML update() consumable hold/use loop (frame units)
	if GameState.state != GameState.State.PLAY and GameState.state != GameState.State.STAGE_CLEAR:
		return
	var df := delta * 60.0
	if e_cd > 0.0:
		e_cd = maxf(0.0, e_cd - df)
	if Input.is_action_pressed("item_use"):
		if not e_held:
			e_held = true
			e_t = 0.0
			e_used = false
		e_t += df
		if e_t >= HOLD_FRAMES and not e_used:
			e_used = true
			if e_cd > 0.0:
				if AudioBus:
					AudioBus.sfx("hit")
				CombatHelpers.flash("⌛ Item cooling down — %ds" % int(ceili(e_cd / 60.0)), 60.0)
			elif consume_selected():
				e_cd = COOLDOWN_FRAMES
	elif e_held:
		e_held = false

func _apply_effect(key: String, p: Node = null) -> void:
	## HTML CONSUMABLES[i].apply()
	if p == null:
		p = get_tree().get_first_node_in_group("player") if get_tree() else null
	match key:
		"honeycomb":
			CombatHelpers.gain_life()
		"wagyu":
			for _i in range(3):
				CombatHelpers.gain_life()
		"bulltears":
			# HTML: power +0.5 toward cap
			GameState.power = minf(CombatHelpers.power_cap(), GameState.power + 0.5)
		"bullsouls":
			GameState.power = minf(CombatHelpers.power_cap(), GameState.power + 1.5)
		"galaxygas":
			GameState.power = minf(CombatHelpers.power_cap(), GameState.power + 3.75)
		"clover":
			GameState.special_meter = minf(100.0, GameState.special_meter + 25.0)
		"stardust":
			if ItemSystem:
				ItemSystem.spawn_stardust()
		"bubbles":
			if ItemSystem:
				ItemSystem.spawn_bubbles()
		"banana":
			if p:
				p.rapid_t = maxf(float(p.get("rapid_t")), 330.0)
			CombatHelpers.flash("🍌 MONKE'S FRENZY!", 80.0)
			if AudioBus:
				AudioBus.sfx("power")
		"vial", "unholy":
			if p:
				p.set("shield_t", maxf(float(p.get("shield_t")), 300.0))
				if p.get("vial_hits") != null:
					p.vial_hits = 3
				if p.get("vial_t") != null:
					p.vial_t = 300.0
			CombatHelpers.flash("🧪 UNHOLY VIAL — VOID WARD!", 80.0)
			if AudioBus:
				AudioBus.sfx("power")
		"wormhole":
			if p:
				p.phase_t = maxf(float(p.get("phase_t")), 180.0)
			CombatHelpers.flash("🌀 WORMHOLE — PHASED!", 80.0)
			if AudioBus:
				AudioBus.sfx("warp")
		_:
			GameState.special_meter = minf(100.0, GameState.special_meter + 40.0)
