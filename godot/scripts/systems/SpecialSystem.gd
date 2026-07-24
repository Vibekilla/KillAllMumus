extends Node
## HTML useSpecial + lasting FX (laser, mech, bearzooka, stampede, etc.).

signal special_used(key: String)

var fx: Array = []  # active special effects
var fx_tick: int = 0

const FRAME := 60.0
const TEAM_PLAYER := 0
const BulletPatterns = preload("res://scripts/combat/BulletPatterns.gd")

func can_use(_key: String) -> bool:
	return GameState.special_meter >= 100.0

func tick(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	# Dual stills: hold FX in place (player dual_lock_pose + dual_hold_fx)
	var pl = get_tree().get_first_node_in_group("player") if get_tree() else null
	if pl and pl.has_meta("dual_lock_pose") and bool(pl.get_meta("dual_lock_pose")) \
			and pl.has_meta("dual_hold_fx") and bool(pl.get_meta("dual_hold_fx")):
		return
	fx_tick += 1
	_update_fx(delta)

func use(key: String, player: Node2D, bullet_pool: Node) -> bool:
	if not can_use(key):
		return false
	GameState.special_meter = 0.0
	ProgressStore.estats_add("specials", 1)
	# HTML: flashMsg={t:70,txt:'★ '+sp.name.toUpperCase()+'!'}
	var sp_name := _special_name(key)
	if CombatHelpers:
		CombatHelpers.flash("★ %s!" % sp_name.to_upper(), 70.0)
	_activate(key, player, bullet_pool)
	special_used.emit(key)
	return true

func _special_name(key: String) -> String:
	for s in DataRegistry.specials if DataRegistry else []:
		if str(s.get("key", "")) == key:
			return str(s.get("name", key))
	var fallback := {
		"laser": "Kraken Cannon", "mech": "SKOL Mech", "bearzooka": "Bearzooka",
		"vault": "Emblem Vaults", "stampede": "Jungle Stampede", "badger": "Honey Badger",
		"sixth": "Sixth Sense", "revenge": "Ourbie’s Revenge", "kiss": "Kiss Me",
		"kraken": "Unleash the Kraken", "void": "Call of the Void",
	}
	return str(fallback.get(key, key))

func _activate(key: String, player: Node2D, bullet_pool: Node) -> void:
	var px = player.global_position.x
	var py = player.global_position.y
	var pf: Rect2 = Config.playfield()
	var aim_a := float(player.get("aim")) if player.get("aim") != null else -PI / 2.0
	match key:
		"laser", "kraken":
			# laser = Kraken Cannon beam; kraken = tentacles (HTML keys)
			if key == "laser":
				fx.append({"type": "laser", "t": 64.0, "w": 58.0, "x": px, "y": py, "ang": aim_a})
			else:
				for i in 5:
					var tx = pf.position.x + 55 + ((float(i) + 0.5) / 5.0) * (pf.size.x - 110)
					var ty = pf.position.y + 100 + randf() * (pf.size.y - 200)
					fx.append({"type": "tentacle", "t": 360.0, "ct": 0.0, "x": tx, "y": ty, "ph": randf() * TAU, "reach": 76.0})
		"mech":
			fx.append({"type": "mech", "t": 240.0, "ct": 0.0, "x": px, "y": py - 52, "face": aim_a})
		"bearzooka":
			fx.append({"type": "bearzooka", "t": 156.0, "ct": 0.0, "x": pf.position.x - 30, "y": pf.position.y + 34})
		"stampede":
			for i in 6:
				fx.append({
					"type": "bull", "t": 100.0,
					"x": pf.position.x + 40 + i * (pf.size.x - 80) / 5.0,
					"y": pf.end.y + 24 + randf() * 40,
					"hit": {},
				})
		"badger":
			for i in 3:
				var dir = -1 if i % 2 else 1
				fx.append({
					"type": "badger", "t": 90.0, "dir": dir,
					"x": (pf.position.x - 30 if dir > 0 else pf.end.x + 30),
					"y": pf.position.y + 70 + i * ((pf.size.y - 140) / 2.0),
					"hit": {},
				})
		"sixth":
			# HTML: slowmoT=300 + screenShake + power sfx; world crawls, Bobina full speed
			if CombatHelpers and CombatHelpers.has_method("start_slowmo"):
				CombatHelpers.start_slowmo(300.0)
			else:
				GameState.set_meta("slowmo", 300.0)
		"revenge":
			for i in 5:
				var bx = pf.position.x + 50 + ((float(i) + 0.5) / 5.0) * (pf.size.x - 100) + randf_range(-18, 18)
				var by = pf.position.y + 70 + randf() * (pf.size.y - 170)
				fx.append({"type": "blackhole", "t": 150.0, "dt": 0.0, "x": bx, "y": by, "r": 0.0, "col": "#3ae66a"})
		"kiss":
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and not e.is_in_group("bosses"):
					e.set("charm", 180.0)
			fx.append({"type": "kiss", "t": 48.0, "r": 0.0, "x": px, "y": py})
		"void":
			for i in 4:
				var a = float(i) / 4.0 * TAU
				fx.append({
					"type": "servitor", "t": 600.0, "hp": 26.0, "maxhp": 26.0, "sz": 2.2,
					"x": px + cos(a) * 38, "y": py + sin(a) * 38, "ct": float(i) * 7.0,
				})
		"vault":
			# Emblem vaults — wave rings (HTML default-ish burst)
			for i in 3:
				fx.append({"type": "wave", "delay": float(i) * 16.0, "r": 0.0, "x": px, "y": py, "hit": {}, "alive": true})
		_:
			for i in 3:
				fx.append({"type": "wave", "delay": float(i) * 16.0, "r": 0.0, "x": px, "y": py, "hit": {}, "alive": true})
	# also ensure bullet_pool reference for FX that shoot
	set_meta("pool", bullet_pool)
	set_meta("player", player)

func _update_fx(delta: float) -> void:
	var df = delta * FRAME
	var player: Node2D = get_meta("player") if has_meta("player") else null
	var pool: Node = get_meta("pool") if has_meta("pool") else null
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	var pf: Rect2 = Config.playfield()

	# slowmo timer owned by CombatHelpers.tick_slowmo (sim frame) — do not double-decrement

	var keep: Array = []
	for f in fx:
		var typ: String = str(f.get("type", ""))
		match typ:
			"laser":
				f["t"] = float(f["t"]) - df
				if player:
					f["x"] = player.global_position.x
					f["y"] = player.global_position.y
					f["ang"] = float(player.get("aim")) if player.get("aim") != null else -PI / 2.0
				_laser_damage(f)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"mech":
				f["t"] = float(f["t"]) - df
				f["ct"] = float(f.get("ct", 0)) + df
				if player:
					var face: float = float(player.get("aim")) if player.get("aim") != null else -PI / 2.0
					var hx = player.global_position.x + cos(face) * 46.0
					var hy = player.global_position.y + sin(face) * 46.0
					f["x"] = float(f["x"]) + (hx - float(f["x"])) * 0.2
					f["y"] = float(f["y"]) + (hy - float(f["y"])) * 0.2
					if int(f["ct"]) % 3 == 0 and pool and pool.has_method("spawn"):
						var wep = GameState.current_weapon
						_option_like(pool, float(f["x"]) - 9, float(f["y"]), face, wep)
						_option_like(pool, float(f["x"]) + 9, float(f["y"]), face, wep)
					# shield: cancel bullets near player
					if pool and pool.has_method("clear_enemy_near"):
						pool.clear_enemy_near(player.global_position, 28.0)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"bearzooka":
				f["t"] = float(f["t"]) - df
				f["ct"] = float(f.get("ct", 0)) + df
				f["x"] = float(f["x"]) + (pf.size.x + 90) / 156.0 * df
				f["y"] = pf.position.y + 34 + sin(float(f["ct"]) * 0.14) * 6.0
				var over = float(f["x"]) > pf.position.x - 14 and float(f["x"]) < pf.end.x + 14
				if over and int(f["ct"]) % 5 == 0:
					fx.append({
						"type": "bombdrop", "t": 150.0,
						"x": float(f["x"]) + randf_range(-36, 36),
						"y": float(f["y"]) + 12,
						"vy": 2.3 + randf() * 0.8,
						"ty": pf.position.y + 80 + randf() * (pf.size.y - 120),
					})
				if over and int(f["ct"]) % 3 == 0 and pool:
					for k in range(-1, 2):
						pool.spawn(Vector2(float(f["x"]) + k * 10, float(f["y"]) + 8),
							Vector2(randf_range(-0.5, 0.5), 9 + randf() * 3) * FRAME, 2.0, Color("ff9a3c"), TEAM_PLAYER)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"bombdrop":
				f["t"] = float(f["t"]) - df
				f["y"] = float(f["y"]) + float(f.get("vy", 2.5)) * df
				f["vy"] = float(f.get("vy", 2.5)) + 0.26 * df
				if float(f["y"]) >= float(f.get("ty", pf.end.y)):
					_explode(float(f["x"]), float(f["ty"]), 62.0, 12.0, pool)
				else:
					keep.append(f)
			"blackhole":
				f["t"] = float(f["t"]) - df
				f["dt"] = float(f.get("dt", 0)) + df
				f["r"] = minf(15.0, float(f.get("r", 0)) + 1.1 * df)
				var pull = 155.0
				for e in get_tree().get_nodes_in_group("enemies"):
					if not is_instance_valid(e):
						continue
					var d: float = Vector2(float(f["x"]), float(f["y"])).distance_to(e.global_position)
					if d < pull and d > 0.01:
						var g = (1.0 - d / pull) * 2.6
						var dir: Vector2 = (Vector2(float(f["x"]), float(f["y"])) - e.global_position).normalized()
						e.global_position += dir * g
						if d < 26.0 and int(f["dt"]) % 8 == 0 and e.has_method("take_damage"):
							e.take_damage(4.0)
				if pool and pool.has_method("clear_enemy_near"):
					pool.clear_enemy_near(Vector2(float(f["x"]), float(f["y"])), float(f["r"]) + 16.0)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"wave":
				if float(f.get("delay", 0)) > 0.0:
					f["delay"] = float(f["delay"]) - df
					keep.append(f)
				else:
					f["r"] = float(f.get("r", 0)) + 9.0 * df
					_ring_damage(float(f["x"]), float(f["y"]), float(f["r"]), 4.0)
					if float(f["r"]) < 280.0:
						keep.append(f)
			"bull", "badger":
				f["t"] = float(f["t"]) - df
				if typ == "bull":
					f["y"] = float(f["y"]) - 6.5 * df
				else:
					f["x"] = float(f["x"]) + float(f.get("dir", 1)) * 7.0 * df
				_ram_damage(f, 40.0, 6.0)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"tentacle":
				f["t"] = float(f["t"]) - df
				f["ct"] = float(f.get("ct", 0)) + df
				if int(f["ct"]) % 10 == 0:
					_ring_damage(float(f["x"]), float(f["y"]), float(f.get("reach", 76)), 3.0)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"servitor":
				f["t"] = float(f["t"]) - df
				f["ct"] = float(f.get("ct", 0)) + df
				if player:
					var a2 = float(f["ct"]) * 0.05
					f["x"] = player.global_position.x + cos(a2) * 42.0
					f["y"] = player.global_position.y + sin(a2) * 42.0
					if int(f["ct"]) % 8 == 0 and pool:
						var tgt = _nearest_enemy(Vector2(float(f["x"]), float(f["y"])))
						if tgt != Vector2.ZERO:
							var ang = (tgt - Vector2(float(f["x"]), float(f["y"]))).angle()
							for b in range(-1, 2):
								var aa = ang + b * 0.16
								var shot = pool.spawn(Vector2(float(f["x"]), float(f["y"])),
									Vector2.from_angle(aa) * 9.0 * FRAME, 3.0, Color("9d6bff"), TEAM_PLAYER)
								if shot and shot.has_method("set_props"):
									shot.set_props({"laser": true, "voidbolt": true, "pshot": true})
				if float(f["t"]) > 0.0:
					keep.append(f)
			"kiss":
				# HTML: f.t--; f.r+=8
				f["t"] = float(f["t"]) - df
				f["r"] = float(f.get("r", 0)) + 8.0 * df
				if float(f["t"]) > 0.0:
					keep.append(f)
			_:
				f["t"] = float(f.get("t", 0)) - df
				if float(f.get("t", 0)) > 0.0:
					keep.append(f)
	fx = keep

func _laser_damage(f: Dictionary) -> void:
	var ang: float = float(f.get("ang", -PI / 2))
	var origin = Vector2(float(f["x"]), float(f["y"]))
	var dir = Vector2.from_angle(ang)
	var half_w: float = float(f.get("w", 58)) * 0.5
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var rx: Vector2 = e.global_position - origin
		var proj = rx.dot(dir)
		if proj < 0 or proj > 600:
			continue
		var perp = absf(rx.x * dir.y - rx.y * dir.x)
		if perp < half_w + 12.0 and e.has_method("take_damage"):
			e.take_damage(2.0 if not e.is_in_group("bosses") else 4.0)

func _ring_damage(x: float, y: float, r: float, dmg: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = Vector2(x, y).distance_to(e.global_position)
		if absf(d - r) < 18.0 and e.has_method("take_damage"):
			e.take_damage(dmg)

func _ram_damage(f: Dictionary, r: float, dmg: float) -> void:
	var pos = Vector2(float(f["x"]), float(f["y"]))
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var id = e.get_instance_id()
		var hit: Dictionary = f.get("hit", {})
		if hit.has(id):
			continue
		if pos.distance_to(e.global_position) < r and e.has_method("take_damage"):
			e.take_damage(dmg)
			hit[id] = true
			f["hit"] = hit

func _explode(x: float, y: float, r: float, dmg: float, pool: Node) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if Vector2(x, y).distance_to(e.global_position) < r and e.has_method("take_damage"):
			e.take_damage(dmg)
	if pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(Vector2(x, y), r * 0.9)

func _option_like(pool: Node, x: float, y: float, aim: float, _wep: String) -> void:
	pool.spawn(Vector2(x, y), Vector2.from_angle(aim) * 15.0 * FRAME, 1.5, Color("8fb8ff"), TEAM_PLAYER)

func _nearest_enemy(from: Vector2) -> Vector2:
	var best = Vector2.ZERO
	var bd = 1e12
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d = from.distance_squared_to(e.global_position)
		if d < bd:
			bd = d
			best = e.global_position
	return best

func get_fx() -> Array:
	return fx
