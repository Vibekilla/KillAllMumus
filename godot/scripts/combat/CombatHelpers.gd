extends Node
## 1:1 HTML combat helpers — threatMul, scoreMult, particles, power, lives, weapons.

const MAX_LIVES := 9
const MAX_BOMBS := 5
const KILL_EXTEND := 50

var particles: Array = []  # {x,y,vx,vy,life,c}
var score_texts: Array = []  # {x,y,txt,color,life}
var flash_msg: Dictionary = {}  # {t, txt}
var kill_extend_count: int = 0

func threat_mul() -> float:
	## HTML threatMul
	return (1.28 if GameState.hell_mode else 1.0) * (1.0 + GameState.ng_plus * 0.16)

func diff_score_mul() -> float:
	return [1.0, 1.5, 2.2][clampi(GameState.difficulty, 0, 2)]

func score_mult() -> float:
	## HTML scoreMult
	return (1.0 + float(rank_index()) * 0.5) * (1.0 + float(GameState.ng_plus)) * diff_score_mul()

func rank_index() -> int:
	## HTML rankIndex
	var idx = 0
	var kills = GameState.total_kills
	for i in range(DataRegistry.ranks.size()):
		var r: Dictionary = DataRegistry.ranks[i]
		if kills >= int(r.get("k", r.get("kills", 0))):
			idx = i
	return idx

func rank_letter() -> String:
	## Prefer DataRegistry if available
	if GameState.has_method("rank_letter"):
		return GameState.rank_letter()
	var ranks = DataRegistry.ranks
	if ranks.is_empty():
		return "D"
	var i = rank_index()
	return str(ranks[i].get("r", ranks[i].get("rank", "D")))

func power_cap() -> float:
	## HTML powerCap
	return [6.0, 5.5, 4.5][clampi(GameState.difficulty, 0, 2)]

func power_gain_mul() -> float:
	return [1.0, 0.7, 0.5][clampi(GameState.difficulty, 0, 2)]

func shot_level() -> int:
	## HTML shotLevel — floor(power) clamped 1..5
	return clampi(int(floor(GameState.power)), 1, 5)

func shot_level_cap() -> int:
	return clampi(int(floor(power_cap())), 1, 5)

func aim_angle(player: Node2D = null) -> float:
	if player and player.get("aim") != null:
		return float(player.aim)
	var p = _player()
	if p and p.get("aim") != null:
		return float(p.aim)
	return -PI / 2.0

func ang_diff(a: float, b: float) -> float:
	## HTML angDiff — absolute shortest angle
	return absf(wrapf(a - b, -PI, PI))

func lerp_angle(a: float, b: float, t: float) -> float:
	## HTML lerpAngle
	var d = fmod(b - a, TAU)
	if d > PI:
		d -= TAU
	if d < -PI:
		d += TAU
	return a + d * t

func body_ctr(p: Dictionary) -> Vector2:
	## HTML bodyCtr — center of Bobina body given face
	var face = float(p.get("face", -PI / 2.0))
	var r = face + PI / 2.0
	var x = float(p.get("x", 0))
	var y = float(p.get("y", 0))
	return Vector2(x - sin(r) * 16.0, (y - 16.0) + cos(r) * 16.0)

func outfit_colors(outfit: String = "") -> Array:
	var key = outfit if outfit != "" else GameState.selected_outfit
	if DataRegistry.outfit_colors.has(key):
		var c = DataRegistry.outfit_colors[key]
		if c is Array and c.size() >= 2:
			return [str(c[0]), str(c[1])]
		if c is Dictionary:
			return [str(c.get("core", "#ff5b8d")), str(c.get("glow", "#ffd6f2"))]
	# outfits.json embeds colors on each outfit
	for o in DataRegistry.outfits:
		if str(o.get("key")) == key and o.get("colors") is Array:
			var arr: Array = o["colors"]
			if arr.size() >= 2:
				return [str(arr[0]), str(arr[1])]
	return ["#ff5b8d", "#ffd6f2"]

func burst(x: float, y: float, c: String = "#ff8ac0") -> void:
	## HTML burst — 16 particles
	for i in range(16):
		particles.append({
			"x": x, "y": y,
			"vx": (randf() - 0.5) * 7.0,
			"vy": (randf() - 0.5) * 7.0,
			"life": 26.0, "c": c,
		})

func sparks(x: float, y: float, c: String = "#ffe08a") -> void:
	## HTML sparks — 5 particles
	for i in range(5):
		particles.append({
			"x": x, "y": y,
			"vx": (randf() - 0.5) * 4.0,
			"vy": (randf() - 0.5) * 4.0,
			"life": 12.0, "c": c,
		})

func pop(x: float, y: float, txt: String, color: String = "#fff") -> void:
	## HTML pop — floating score text
	score_texts.append({"x": x, "y": y, "txt": txt, "color": color, "life": 44.0})

func flash(txt: String, t: float = 70.0) -> void:
	flash_msg = {"t": t, "txt": txt}

func add_power(a: float) -> void:
	## HTML addPower
	var before = shot_level()
	GameState.power = minf(power_cap(), GameState.power + a * power_gain_mul())
	var lv = shot_level()
	if lv > before:
		var p = _player()
		var px = p.global_position.x if p else 0.0
		var py = (p.global_position.y - 30.0) if p else 0.0
		pop(px, py, "POWER UP! Lv%d" % lv, "#ffd27a")
		if lv >= shot_level_cap():
			flash("★ MAX POWER — LV%d ★" % lv, 70.0)
		else:
			flash("POWER UP", 70.0)
		if AudioBus:
			AudioBus.sfx("power")

func gain_life() -> void:
	## HTML gainLife
	if GameState.lives < MAX_LIVES:
		GameState.lives += 1
		if AudioBus:
			AudioBus.sfx("extend")
		flash("1UP!", 90.0)
		var p = _player()
		if p:
			pop(p.global_position.x, p.global_position.y - 30.0, "1UP", "#ff4d8d")
	else:
		GameState.add_score(50000)

func check_extend() -> void:
	## HTML checkExtend / killExtend — every KILL_EXTEND kills → life
	kill_extend_count += 1
	if kill_extend_count >= KILL_EXTEND:
		kill_extend_count = 0
		gain_life()

func swap_weapon() -> void:
	## HTML swapWeapon
	if GameState.weapons.size() < 2:
		return
	var i = GameState.weapons.find(GameState.current_weapon)
	if i < 0:
		i = 0
	GameState.current_weapon = GameState.weapons[(i + 1) % GameState.weapons.size()]
	if AudioBus:
		AudioBus.sfx("item")
	var wpn_key = GameState.current_weapon
	var wpn_label = wpn_key
	if DataRegistry.weapons.has(wpn_key):
		wpn_label = str(DataRegistry.weapons[wpn_key].get("name", wpn_key))
	flash("▸ " + wpn_label, 70.0)

func cycle_special() -> void:
	## HTML cycleSpecial
	if GameState.specials.size() < 2:
		return
	var p = _player()
	var armed = 0
	if p and p.get("armed_special") != null:
		armed = int(p.armed_special)
	armed = (armed + 1) % GameState.specials.size()
	if p:
		p.set("armed_special", armed)
	if AudioBus:
		AudioBus.sfx("item")
	var key = str(GameState.specials[armed])
	var nm = key
	for s in DataRegistry.specials:
		if str(s.get("key")) == key:
			nm = str(s.get("name", key))
			break
	flash("SPECIAL ▸ " + nm, 60.0)

func nearest_target(x: float, y: float) -> Node2D:
	## HTML nearestTarget
	var tree = get_tree()
	if tree == null:
		return null
	var best: Node2D = null
	var bd = 1e18
	var origin = Vector2(x, y)
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d = origin.distance_squared_to(e.global_position)
		if d < bd:
			bd = d
			best = e
	return best

func line_time(text: String) -> float:
	## HTML lineTime for dialog
	return minf(280.0, 90.0 + float(text.length()) * 2.7)

func tick_fx(delta: float) -> void:
	# HTML sim is frame-based @60; scale by df frames elapsed
	var df = delta * 60.0
	var keep_p: Array = []
	for p in particles:
		# per-frame velocity (HTML particles push vx in px/frame)
		p["x"] = float(p.get("x", 0)) + float(p.get("vx", 0)) * df
		p["y"] = float(p.get("y", 0)) + float(p.get("vy", 0)) * df
		p["life"] = float(p.get("life", 0)) - df
		if float(p["life"]) > 0.0:
			keep_p.append(p)
	particles = keep_p
	var keep_s: Array = []
	for s in score_texts:
		s["y"] = float(s.get("y", 0)) - 0.6 * df
		s["life"] = float(s.get("life", 0)) - df
		if float(s["life"]) > 0.0:
			keep_s.append(s)
	score_texts = keep_s
	if flash_msg.has("t"):
		flash_msg["t"] = float(flash_msg.get("t", 0)) - df
		if float(flash_msg["t"]) <= 0.0:
			flash_msg = {}

func boss_dmg_mul() -> float:
	## HTML bossDmgMul — soften high power vs bosses
	var lv := clampf(GameState.power, 1.0, 5.0)
	return 1.0 / (0.75 + lv * 0.12)

func boss_wep_mul() -> float:
	## HTML bossWepMul
	return 0.85 if GameState.hard_mode else 1.0

func bullet_cancel_all(pool: Node = null) -> void:
	## HTML bulletCancelAll
	var p = pool
	if p == null:
		p = _bullet_pool()
	if p and p.has_method("clear_enemy"):
		p.clear_enemy()

func bullet_cancel_near(pool: Node, pos: Vector2, r: float) -> void:
	## HTML bulletCancelNear
	if pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(pos, r)

var melee_fx: Array = []  # HTML meleeFx rings/swipes
var screen_shake: float = 0.0

func rgb_hue(h: float, s: float = 1.0, l: float = 0.66) -> String:
	## HTML _rgbHue → hsl string for particle colors
	return "hsl(%d,%d%%,%d%%)" % [int(h) % 360, int(s * 100.0), int(l * 100.0)]

func dash_land_explosion(player: Node2D, slash: bool = false) -> void:
	## HTML dashLandExplosion
	if player == null:
		return
	var base := float((SimClock.sim_frame if SimClock else 0) * 4)
	var n := 26 if slash else 16
	var px := player.global_position.x
	var py := player.global_position.y
	for i in range(n):
		var a := float(i) / float(n) * TAU + randf() * 0.2
		var sp := (4.0 if slash else 2.6) + randf() * (4.5 if slash else 3.0)
		var hue := fmod(base + float(i) * (360.0 / float(n)), 360.0)
		particles.append({
			"x": px, "y": py,
			"vx": cos(a) * sp, "vy": sin(a) * sp,
			"life": 15.0 + float(randi() % 16),
			"c": rgb_hue(hue),
		})
	melee_fx.append({
		"ring": true, "rainbow": true,
		"x": px, "y": py,
		"r0": 5.0, "r1": 62.0 if slash else 42.0,
		"col": "#fff", "life": 18.0, "t": 0.0,
	})
	screen_shake = maxf(screen_shake, 4.5 if slash else 2.2)
	if AudioBus:
		AudioBus.sfx("item")
		if slash:
			AudioBus.sfx("graze")

func clear_wave_mobs() -> void:
	## HTML clearWaveMobs
	var tree = get_tree()
	if tree == null:
		return
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.is_in_group("bosses"):
			continue
		var icy := bool(e.get("icy")) if e.get("icy") != null else false
		burst(e.global_position.x, e.global_position.y, "#a0e0ff" if icy else "#ffd27a")
		GameState.add_score(int(50.0 * score_mult()))
		e.queue_free()
	bullet_cancel_all()

func _bullet_pool() -> Node:
	var tree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("bullet_pool")

func _player() -> Node2D:
	var tree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node2D
