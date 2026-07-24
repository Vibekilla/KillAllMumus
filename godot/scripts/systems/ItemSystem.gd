extends Node
## 1:1 HTML items / loot / floaters / burns / killEnemy side-effects.

const FRAME := 60.0
const EXTEND_SCORES := [300000, 800000, 1600000]
const MAX_BOMBS := 5

var items: Array = []  # {x,y,vx,vy,type,t,homing,val?,wep?}
var floaters: Array = []  # {x,y,life,vy,scale}
var emotes: Array = []  # {x,y,life,kind}
var burns: Array = []  # flame fields from charged melee
var life_frags: int = 0
var bomb_frags: int = 0
var extend_idx: int = 0
var kills_this_stage: int = 0

func reset_run() -> void:
	items.clear()
	floaters.clear()
	emotes.clear()
	burns.clear()
	life_frags = 0
	bomb_frags = 0
	extend_idx = 0
	kills_this_stage = 0
	CombatHelpers.kill_extend_count = 0

func drop_item(x: float, y: float, type: String, extra: Dictionary = {}) -> void:
	## HTML dropItem
	var it := {
		"x": x, "y": y,
		"vx": (randf() - 0.5) * 1.2,
		"vy": -2.0 - randf() * 1.5,
		"type": type, "t": 0.0, "homing": false,
	}
	for k in extra.keys():
		it[k] = extra[k]
	items.append(it)

func drop_weapon(x: float, y: float) -> void:
	drop_item(x, y, "fullpower")

func drop_loot(e: Dictionary) -> void:
	## HTML dropLoot — e: {x,y,kind,icy?}
	var kind := str(e.get("kind", "lil"))
	var x := float(e.get("x", 0))
	var y := float(e.get("y", 0))
	if kind == "elite":
		for i in range(4):
			drop_item(x + (randf() - 0.5) * 30.0, y, "point")
		if randf() < 0.30:
			drop_item(x, y, "life")
		if randf() < 0.30:
			drop_item(x, y, "bomb")
		if randf() < 0.12:
			drop_item(x, y, "shield")
	elif kind == "big":
		for i in range(2):
			drop_item(x + (randf() - 0.5) * 20.0, y, "power")
		for i in range(3):
			drop_item(x + (randf() - 0.5) * 24.0, y, "point")
		if randf() < 0.30:
			drop_item(x, y, "life")
		if randf() < 0.28:
			drop_item(x, y, "bomb")
		if randf() < 0.09:
			drop_weapon(x, y)
		if randf() < 0.10:
			drop_item(x, y, "shield")
	else:
		var r := randf()
		if r < 0.13:
			drop_item(x, y, "power")
		elif r < 0.58:
			drop_item(x, y, "point")

func kill_enemy(e: Dictionary, silent: bool = false) -> void:
	## HTML killEnemy (score/loot/FX side) — node already freeing itself
	var kind := str(e.get("kind", "lil"))
	var x := float(e.get("x", 0))
	var y := float(e.get("y", 0))
	var icy := bool(e.get("icy", false))
	kills_this_stage += 1
	if randf() < 0.06:
		drop_item(x, y, "skull", {"val": 30 if kind == "big" else 10})
	ProgressStore.estats_add("kills", 1)
	if not ProgressStore.has_emblem("first_mumu"):
		ProgressStore.unlock_emblem("first_mumu")
	var ek := int(ProgressStore.estats.get("kills", 0))
	if ek >= 500:
		ProgressStore.unlock_emblem("kills_500")
	if ek >= 2500:
		ProgressStore.unlock_emblem("kills_2500")
	if ek >= 5000:
		ProgressStore.unlock_emblem("kills_5000")
	if ek >= 10000:
		ProgressStore.unlock_emblem("kills_10000")
	var pts := int(floor((500.0 if kind == "big" else 100.0) * CombatHelpers.score_mult()))
	# EnemyBase already adds score — avoid double if caller handled; kill_enemy used as canonical
	CombatHelpers.burst(x, y, "#9fe0ff" if icy else "#ff9ecb")
	floaters.append({"x": x, "y": y, "life": 30.0, "vy": -0.7, "scale": 1.0 if kind == "big" else 0.62})
	drop_loot(e)
	if kind == "elite":
		CombatHelpers.add_power(1.5)
		CombatHelpers.pop(x, y - 24.0, "ELITE DOWN — POWER +", "#ffd27a")
	if kind == "big":
		var pool := _bullet_pool()
		if pool and pool.has_method("clear_enemy_near"):
			pool.clear_enemy_near(Vector2(x, y), 80.0)
	GameState.special_meter = minf(100.0, GameState.special_meter + (4.0 if kind == "big" else 1.4))
	if not silent and AudioBus:
		AudioBus.sfx("kill")
	# kill extend every 50 total kills
	if GameState.total_kills > 0 and GameState.total_kills % CombatHelpers.KILL_EXTEND == 0:
		kill_extend()
	check_extend_score()

func kill_extend() -> void:
	## HTML killExtend
	if GameState.lives < CombatHelpers.MAX_LIVES:
		GameState.lives += 1
		if AudioBus:
			AudioBus.sfx("extend")
		CombatHelpers.flash("MUMU SLAYER — 1UP!", 110.0)
		var p := _player()
		if p:
			CombatHelpers.pop(p.global_position.x, p.global_position.y - 32.0, "1UP", "#ff4d8d")
			for i in range(20):
				CombatHelpers.particles.append({
					"x": p.global_position.x, "y": p.global_position.y,
					"vx": (randf() - 0.5) * 8.0, "vy": (randf() - 0.5) * 8.0,
					"life": 30.0, "c": "#ff6ec7",
				})
	else:
		GameState.add_score(50000)
		CombatHelpers.flash("MUMU SLAYER BONUS!", 80.0)

func check_extend_score() -> void:
	## HTML checkExtend — score thresholds
	while extend_idx < EXTEND_SCORES.size() and GameState.session_score >= EXTEND_SCORES[extend_idx]:
		extend_idx += 1
		CombatHelpers.gain_life()

func elite_hearts() -> int:
	return mini(5, 2 + GameState.difficulty + GameState.ng_plus)

func emote(kind: String) -> void:
	## HTML emote — currently no-op in HTML ("removed by request") but keep API
	# Soft re-enable small bubble for juice (optional): skip to match HTML empty body
	pass

func collect_item(it: Dictionary) -> void:
	## HTML collectItem
	var type := str(it.get("type", ""))
	if AudioBus:
		AudioBus.sfx("power" if type in ["power", "fullpower"] else "item")
	var x := float(it.get("x", 0))
	var y := float(it.get("y", 0))
	var p := _player()
	match type:
		"power":
			CombatHelpers.add_power(0.05)
			CombatHelpers.pop(x, y, "+P", "#ff8ad6")
		"fullpower":
			GameState.power = CombatHelpers.power_cap()
			CombatHelpers.pop(x, y, "FULL POWER", "#ffd27a")
			CombatHelpers.flash("★ FULL POWER ★", 90.0)
		"point":
			var v := int(floor(500.0 * CombatHelpers.score_mult()))
			GameState.add_score(v)
			CombatHelpers.pop(x, y, "+%d" % v, "#8fd0ff")
		"life":
			life_frags += 1
			if life_frags >= 5:
				life_frags = 0
				CombatHelpers.gain_life()
			else:
				CombatHelpers.pop(x, y, "♥ frag", "#ff6ec7")
		"bomb":
			bomb_frags += 1
			if bomb_frags >= 3:
				bomb_frags = 0
				if GameState.bombs < MAX_BOMBS:
					GameState.bombs += 1
					CombatHelpers.pop(x, y, "✸ +BOMB", "#ffd27a")
			else:
				CombatHelpers.pop(x, y, "✸ frag", "#ffd27a")
		"weapon":
			var wep := str(it.get("wep", "laser"))
			var nw := GameState.weapons.find(wep) < 0
			if nw:
				GameState.weapons.append(wep)
			GameState.current_weapon = wep
			var nm := wep
			if DataRegistry.weapons.has(wep):
				nm = str(DataRegistry.weapons[wep].get("name", wep))
			CombatHelpers.flash(("%s%s" % ["NEW WEAPON: " if nw else "", nm]), 120.0)
			var col := "#ffd27a"
			if DataRegistry.weapons.has(wep):
				col = str(DataRegistry.weapons[wep].get("col", col))
			CombatHelpers.pop(x, y, nm, col)
		"shield":
			if p:
				p.shield_t = maxf(float(p.shield_t), 290.0)
			if AudioBus:
				AudioBus.sfx("power")
			CombatHelpers.flash("BOBO GUARD UP!", 80.0)
			CombatHelpers.pop(x, y, "BOBO GUARD", "#e8a860")
		"rapid":
			if p:
				p.rapid_t = maxf(float(p.rapid_t), 270.0)
			if AudioBus:
				AudioBus.sfx("power")
			CombatHelpers.flash("🦍 MONKE FRENZY!", 80.0)
			CombatHelpers.pop(x, y, "🦍 MONKE", "#ffe14a")
		"skull":
			var v2 := int(it.get("val", 10))
			ProgressStore.progress["heads"] = int(ProgressStore.progress.get("heads", 0)) + v2
			ProgressStore.queue_save()
			CombatHelpers.pop(x, y, "💀 +%d" % v2, "#ffe0a0")

func tick(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	var df := delta * FRAME
	_update_items(df)
	_update_floaters(df)
	_update_emotes(df)
	_update_burns(df)
	check_extend_score()

func _update_items(df: float) -> void:
	var p := _player()
	# Dual stills: freeze pickups in place (no magnet / collect / drift)
	var dual := bool(GameState.get_meta("dual_mode", false)) if GameState else false
	if dual:
		for it in items:
			it["vx"] = 0.0
			it["vy"] = 0.0
			it["homing"] = false
		return
	var auto_all := false
	var magnet := 70.0
	if p and is_instance_valid(p):
		auto_all = p.global_position.y < Config.COLLECT_LINE
		magnet = 150.0 if bool(p.get("focus")) else 70.0
	var keep: Array = []
	for it in items:
		it["t"] = float(it.get("t", 0)) + df
		if p and is_instance_valid(p):
			var dx := p.global_position.x - float(it.x)
			var dy := p.global_position.y - float(it.y)
			var d := sqrt(dx * dx + dy * dy)
			if auto_all or d < magnet:
				it["homing"] = true
			if bool(it.get("homing", false)) and d > 0.01:
				var sp := minf(9.0, 3.0 + float(it.t) * 0.1)
				it["vx"] = float(it.vx) + dx / d * 1.2 * df
				it["vy"] = float(it.vy) + dy / d * 1.2 * df
				var s := sqrt(float(it.vx) * float(it.vx) + float(it.vy) * float(it.vy))
				if s > sp:
					it["vx"] = float(it.vx) * sp / s
					it["vy"] = float(it.vy) * sp / s
			if d < 14.0:
				collect_item(it)
				continue
		if not bool(it.get("homing", false)):
			it["vy"] = float(it.vy) + 0.12 * df
			if float(it.vy) > 3.0:
				it["vy"] = 3.0
			it["vx"] = float(it.vx) * pow(0.96, df)
		it["x"] = float(it.x) + float(it.vx) * df
		it["y"] = float(it.y) + float(it.vy) * df
		var pf: Rect2 = Config.playfield()
		if float(it.y) > pf.end.y + 30.0:
			continue
		keep.append(it)
	items = keep

func _update_floaters(df: float) -> void:
	var keep: Array = []
	for f in floaters:
		f["life"] = float(f.get("life", 0)) - df
		f["y"] = float(f.y) + float(f.get("vy", -0.7)) * df
		if float(f["life"]) > 0.0:
			keep.append(f)
	floaters = keep

func _update_emotes(df: float) -> void:
	var keep: Array = []
	for em in emotes:
		em["life"] = float(em.get("life", 0)) - df
		if float(em["life"]) > 0.0:
			keep.append(em)
	emotes = keep

func add_burn(x: float, y: float, dir: float, reach: float, half: float, col: String = "#ff7a2a", life: float = 90.0) -> void:
	burns.append({
		"x": x, "y": y, "dir": dir, "reach": reach, "half": half,
		"col": col, "life": life, "max": life, "dt": 0.0,
	})

func _update_burns(df: float) -> void:
	if burns.is_empty():
		return
	var tree := get_tree()
	var keep: Array = []
	for bn in burns:
		bn["life"] = float(bn.life) - df
		bn["dt"] = float(bn.get("dt", 0)) + df
		var prev_dt = float(bn.dt) - df
		if int(floor(float(bn.dt) / 6.0)) > int(floor(prev_dt / 6.0)):
			# damage tick every ~6 frames
			if tree:
				for e in tree.get_nodes_in_group("enemies"):
					if not is_instance_valid(e):
						continue
					var dx: float = e.global_position.x - float(bn.x)
					var dy: float = e.global_position.y - float(bn.y)
					var d := sqrt(dx * dx + dy * dy)
					if d < float(bn.reach) and CombatHelpers.ang_diff(atan2(dy, dx), float(bn.dir)) < float(bn.half):
						if e.has_method("take_damage"):
							e.take_damage(2.0)
							e.set("flash", 4.0)
				# clear enemy bullets near burn cone
				var pool := _bullet_pool()
				if pool and pool.has_method("clear_enemy_near"):
					pool.clear_enemy_near(Vector2(float(bn.x), float(bn.y)), float(bn.reach) * 0.9)
			# particles
			var a := float(bn.dir) - float(bn.half) + randf() * float(bn.half) * 2.0
			var rr := float(bn.reach) * (0.3 + randf() * 0.7)
			CombatHelpers.particles.append({
				"x": float(bn.x) + cos(a) * rr,
				"y": float(bn.y) + sin(a) * rr,
				"vx": (randf() - 0.5) * 1.5,
				"vy": -1.4 - randf() * 1.6,
				"life": 14.0 + randf() * 8.0,
				"c": "#fff" if randf() < 0.4 else (str(bn.col) if randf() < 0.5 else "#ff7a2a"),
			})
		if float(bn.life) > 0.0:
			keep.append(bn)
	burns = keep

func chain_lightning(sx: float, sy: float, dmg: float, jumps: int, col: String = "#8fd0ff") -> void:
	## HTML chainLightning
	var x := sx
	var y := sy
	var hit: Dictionary = {}
	var pts: Array = [{"x": x, "y": y}]
	var tree := get_tree()
	if tree == null:
		return
	for j in range(jumps):
		var best: Node2D = null
		var bd := 1e9
		for e in tree.get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or hit.has(e.get_instance_id()):
				continue
			if e.is_in_group("bosses"):
				continue
			var d := Vector2(x, y).distance_to(e.global_position)
			if d < 175.0 and d < bd:
				bd = d
				best = e
		if best == null:
			break
		hit[best.get_instance_id()] = true
		if best.has_method("take_damage"):
			best.take_damage(dmg + 2.0)
		best.set("flash", 6.0)
		best.set("stun", maxf(float(best.get("stun")), 24.0))
		x = best.global_position.x
		y = best.global_position.y
		pts.append({"x": x, "y": y})
		for s in range(4):
			CombatHelpers.particles.append({
				"x": x, "y": y,
				"vx": (randf() - 0.5) * 4.0, "vy": (randf() - 0.5) * 4.0,
				"life": 12.0, "c": col if s % 2 == 0 else "#fff",
			})
	# bolt fx via meleeFx-style — store as floater chain particles
	if pts.size() > 1:
		for i in range(pts.size() - 1):
			var a: Dictionary = pts[i]
			var b: Dictionary = pts[i + 1]
			for k in range(6):
				var u := float(k) / 6.0
				CombatHelpers.particles.append({
					"x": lerpf(float(a.x), float(b.x), u),
					"y": lerpf(float(a.y), float(b.y), u),
					"vx": 0.0, "vy": 0.0, "life": 12.0, "c": col,
				})

func nade_boom(x: float, y: float) -> void:
	## HTML nadeBoom
	CombatHelpers.burst(x, y, "#b6e34a")
	if AudioBus:
		AudioBus.sfx("bomb", 0.6)
	for i in range(14):
		CombatHelpers.particles.append({
			"x": x, "y": y,
			"vx": (randf() - 0.5) * 8.0, "vy": (randf() - 0.5) * 8.0,
			"life": 20.0, "c": "#b6e34a" if i % 2 == 0 else "#fff",
		})
	var tree := get_tree()
	if tree:
		for e in tree.get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			var d := Vector2(x, y).distance_to(e.global_position)
			if e.is_in_group("bosses"):
				if d < 58.0 and e.has_method("take_damage"):
					e.take_damage(2.0)
			elif d < 50.0 and e.has_method("take_damage"):
				e.take_damage(8.0)
		var pool := _bullet_pool()
		if pool and pool.has_method("clear_enemy_near"):
			pool.clear_enemy_near(Vector2(x, y), 44.0)

func enemy_explode(e: Node2D) -> void:
	## HTML enemyExplode
	if e.get("_exploded"):
		return
	e.set("_exploded", true)
	var x := e.global_position.x
	var y := e.global_position.y
	CombatHelpers.burst(x, y, "#ffd27a")
	for i in range(12):
		CombatHelpers.particles.append({
			"x": x, "y": y,
			"vx": (randf() - 0.5) * 9.0, "vy": (randf() - 0.5) * 9.0,
			"life": 22.0, "c": "#ffd27a" if i % 2 == 0 else "#fff",
		})
	var tree := get_tree()
	if tree:
		for o in tree.get_nodes_in_group("enemies"):
			if o == e or not is_instance_valid(o):
				continue
			if o.global_position.distance_to(e.global_position) < 46.0 and o.has_method("take_damage"):
				o.take_damage(6.0)
		var pool := _bullet_pool()
		if pool and pool.has_method("clear_enemy_near"):
			pool.clear_enemy_near(e.global_position, 42.0)
	if e.has_method("take_damage"):
		e.take_damage(9999.0)
	if AudioBus:
		AudioBus.sfx("hit")

func spawn_bubbles() -> void:
	## HTML spawnBubbles — ring of trap bubbles as floaters/fx particles for now
	var p := _player()
	if p == null:
		return
	for i in range(6):
		var a := float(i) / 6.0 * TAU + float(i) * 0.7
		var sp := 1.5 + float(i) * 0.15
		items.append({
			"x": p.global_position.x, "y": p.global_position.y - 8.0,
			"vx": cos(a) * sp, "vy": sin(a) * sp - 0.6,
			"type": "point", "t": 0.0, "homing": false,  # temporary stand-in
			"_bubble": true, "r": 9.0, "life": 120.0 + float(i) * 8.0,
		})
	if AudioBus:
		AudioBus.sfx("power")

func spawn_stardust() -> void:
	var p := _player()
	if p == null:
		return
	# orbiting damage ticks via burn-like short fields
	add_burn(p.global_position.x, p.global_position.y - 14.0, 0.0, 48.0, TAU, "#ffe08a", 270.0)
	if AudioBus:
		AudioBus.sfx("power")

func _player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node2D

func _bullet_pool() -> Node:
	var p := _player()
	if p and p.get("bullet_pool") != null:
		return p.bullet_pool
	var tree := get_tree()
	if tree:
		return tree.get_first_node_in_group("bullet_pool")
	return null
