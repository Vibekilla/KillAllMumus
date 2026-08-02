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

func clear_field() -> void:
	## HTML loadStage: fx=[] (and slowmo ends with stage)
	fx.clear()
	fx_tick = 0
	if CombatHelpers and CombatHelpers.has_method("end_slowmo"):
		CombatHelpers.end_slowmo()
	elif GameState and GameState.has_meta("slowmo"):
		GameState.remove_meta("slowmo")

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
	if player and bool(player.get("dead")):
		return false
	GameState.special_meter = 0.0
	ProgressStore.estats_add("specials", 1)
	if int(ProgressStore.estats.get("specials", 0)) >= 25:
		ProgressStore.unlock_emblem("special_25")
	# HTML: sfx('bomb'); flashMsg={t:70,txt:'★ '+sp.name.toUpperCase()+'!'}
	if AudioBus:
		AudioBus.sfx("bomb")
	var sp_name := _special_name(key)
	if CombatHelpers:
		CombatHelpers.flash("★ %s!" % sp_name.to_upper(), 70.0)
	_activate(key, player, bullet_pool)
	# HTML: 30 particles in sp.col
	var col := "#ffd27a"
	if DataRegistry:
		for s in DataRegistry.specials:
			if str(s.get("key", "")) == key:
				col = str(s.get("col", col))
				break
	if CombatHelpers:
		var px := player.global_position.x
		var py := player.global_position.y
		for i in range(30):
			CombatHelpers.particles.append({
				"x": px, "y": py,
				"vx": (randf() - 0.5) * 12.0, "vy": (randf() - 0.5) * 12.0,
				"life": 30.0, "c": col,
			})
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
				# HTML Kraken Cannon: follow player aim; dmg 2/4; cancel non-shell bullets on beam
				f["t"] = float(f["t"]) - df
				if player:
					f["x"] = player.global_position.x
					f["y"] = player.global_position.y
					f["ang"] = float(player.get("aim")) if player.get("aim") != null else -PI / 2.0
				_laser_tick(f, pool, pf)
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
					f["x"] = clampf(float(f["x"]), pf.position.x + 16.0, pf.end.x - 16.0)
					f["y"] = clampf(float(f["y"]), pf.position.y + 18.0, pf.end.y - 18.0)
					f["face"] = face
					# HTML: optionShot weapon-matched, ct%3 both cannons
					if int(f["ct"]) % 3 == 0 and pool:
						var wep = GameState.current_weapon
						_option_like(pool, float(f["x"]) - 9, float(f["y"]), face, wep)
						_option_like(pool, float(f["x"]) + 9, float(f["y"]), face, wep)
						if int(f["ct"]) % 9 == 0 and AudioBus:
							AudioBus.sfx("shoot")
					# HTML mech shield: shells keep, floaters only
					if pool and pool.has_method("clear_enemy_near"):
						pool.clear_enemy_near(player.global_position, 28.0, false)
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
					# HTML: mob r62 dmg12; boss r70 dmg6; shake 4.5; soft bullet clear r54
					_bombdrop_explode(float(f["x"]), float(f["ty"]), pool)
				else:
					keep.append(f)
			"blackhole":
				# HTML: launch dt<16 (vx/vy*0.9), settle, pull mobs, boss chip 3/12f,
				# spiral soft bullets (devour d<16). Boss is NOT pulled.
				f["t"] = float(f["t"]) - df
				f["dt"] = float(f.get("dt", 0)) + df
				var dt_bh := float(f["dt"])
				if dt_bh < 16.0:
					f["x"] = float(f["x"]) + float(f.get("vx", 0.0)) * df
					f["y"] = float(f["y"]) + float(f.get("vy", 0.0)) * df
					f["vx"] = float(f.get("vx", 0.0)) * pow(0.9, df)
					f["vy"] = float(f.get("vy", 0.0)) * pow(0.9, df)
				f["x"] = clampf(float(f["x"]), pf.position.x + 24.0, pf.end.x - 24.0)
				f["y"] = clampf(float(f["y"]), pf.position.y + 24.0, pf.end.y - 24.0)
				f["r"] = minf(15.0, float(f.get("r", 0)) + 1.1 * df)
				_blackhole_tick(f, pool, pf)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"wave":
				# HTML Emblem Vaults: expand ring r+=9; annulus lo=r-14 hi=r+6;
				# mob 5 once / boss 14 once; cancel bullets in ring; die when r>PF.w+PF.h
				if float(f.get("delay", 0)) > 0.0:
					f["delay"] = float(f["delay"]) - df
					keep.append(f)
				else:
					f["r"] = float(f.get("r", 0)) + 9.0 * df
					_wave_ring_tick(f, pool)
					if float(f["r"]) <= pf.size.x + pf.size.y:
						keep.append(f)
					else:
						f["alive"] = false
			"bull", "badger":
				# HTML bull: y-=9.5, mob 7 once, boss 3 continuous
				# HTML badger: x+=dir*12, mob 8 once, boss 3 continuous
				f["t"] = float(f["t"]) - df
				if typ == "bull":
					f["y"] = float(f["y"]) - 9.5 * df
					f["x"] = float(f["x"]) + sin((100.0 - float(f["t"])) * 0.2) * 0.6 * df
					_stampede_tick(f, pool, true)
				else:
					f["x"] = float(f["x"]) + float(f.get("dir", 1)) * 12.0 * df
					f["y"] = float(f["y"]) + sin((90.0 - float(f["t"])) * 0.3) * 1.2 * df
					_stampede_tick(f, pool, false)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"tentacle":
				# HTML: d < reach pull; dmg 4 every 9f mobs, boss 2 every 12f
				f["t"] = float(f["t"]) - df
				f["ct"] = float(f.get("ct", 0)) + df
				f["ph"] = float(f.get("ph", 0)) + 0.13 * df
				_tentacle_tick(f)
				if float(f["t"]) > 0.0:
					keep.append(f)
			"servitor":
				# HTML Call of the Void — hunt nearest mumu (or boss), fire voidbolts, soak bullets
				f["t"] = float(f["t"]) - df
				f["ct"] = float(f.get("ct", 0)) + df
				if _servitor_tick(f, pool, pf):
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

func _laser_tick(f: Dictionary, pool: Node, pf: Rect2) -> void:
	## HTML laser beam: onBeam with entity radius; mob 2 / boss 4; cancel bullets
	var ang: float = float(f.get("ang", -PI / 2))
	var origin := Vector2(float(f["x"]), float(f["y"]))
	var dir := Vector2.from_angle(ang)
	var half_w: float = float(f.get("w", 58)) * 0.5
	var max_proj := pf.size.x + pf.size.y
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		var er := float(e.get("radius")) if e.get("radius") != null else 15.0
		var rx: Vector2 = e.global_position - origin
		var proj := rx.dot(dir)
		if proj < 0.0 or proj > max_proj:
			continue
		var perp := absf(rx.x * dir.y - rx.y * dir.x)
		if perp < half_w + er:
			var is_boss := e.is_in_group("bosses")
			e.take_damage(4.0 if is_boss else 2.0)
			if "flash" in e:
				e.flash = 3.0 if is_boss else 4.0
	# cancel non-shell bullets on beam
	if pool:
		for b in pool.iter_active() if pool.has_method("iter_active") else []:
			if not is_instance_valid(b) or int(b.team) != 1:
				continue
			if float(b.get("hp")) > 0.0:
				continue
			var brx: Vector2 = b.global_position - origin
			var bproj := brx.dot(dir)
			if bproj < 0.0 or bproj > max_proj:
				continue
			var bperp := absf(brx.x * dir.y - brx.y * dir.x)
			if bperp < half_w:
				b.deactivate()
	# HTML sparks along beam every 3 frames
	if int(f.get("t", 0)) % 3 == 0 and CombatHelpers:
		var d := 40.0 + randf() * 300.0
		CombatHelpers.particles.append({
			"x": origin.x + dir.x * d, "y": origin.y + dir.y * d,
			"vx": (randf() - 0.5) * 2.0, "vy": (randf() - 0.5) * 2.0,
			"life": 10.0, "c": "#c9a0ff",
		})

func _laser_damage(f: Dictionary) -> void:
	## Backward-compatible wrapper
	_laser_tick(f, null, Config.playfield())

func _ring_damage(x: float, y: float, r: float, dmg: float) -> void:
	## Generic thin ring (legacy); vault waves use _wave_ring_tick
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = Vector2(x, y).distance_to(e.global_position)
		if absf(d - r) < 18.0 and e.has_method("take_damage"):
			e.take_damage(dmg)

func _wave_ring_tick(f: Dictionary, pool: Node) -> void:
	## HTML wave special — annulus hit-once + soft bullet cancel
	var x := float(f["x"])
	var y := float(f["y"])
	var r := float(f["r"])
	var lo := r - 14.0
	var hi := r + 6.0
	var hit: Dictionary = f.get("hit", {})
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var id := e.get_instance_id()
		if hit.has(id):
			continue
		var d := Vector2(x, y).distance_to(e.global_position)
		if d > lo and d < hi and e.has_method("take_damage"):
			hit[id] = true
			var is_boss := e.is_in_group("bosses")
			e.take_damage(14.0 if is_boss else 5.0)
			if "flash" in e:
				e.flash = 5.0
	f["hit"] = hit
	if pool and pool.has_method("cancel_enemy_in_annulus"):
		pool.cancel_enemy_in_annulus(Vector2(x, y), lo, hi)
	elif pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(Vector2(x, y), hi, false)

func _stampede_tick(f: Dictionary, pool: Node, is_bull: bool) -> void:
	## HTML bull / badger charge — hit-set for mobs; continuous boss chip
	var fx := float(f["x"])
	var fy := float(f["y"])
	var hit: Dictionary = f.get("hit", {})
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		var er := float(e.get("radius")) if e.get("radius") != null else 15.0
		var is_boss := e.is_in_group("bosses")
		if is_bull:
			if is_boss:
				if absf(e.global_position.x - fx) < 28.0 + er and absf(e.global_position.y - fy) < 34.0:
					e.take_damage(3.0)
					if "flash" in e:
						e.flash = 4.0
			else:
				var id := e.get_instance_id()
				if hit.has(id):
					continue
				if absf(e.global_position.x - fx) < 24.0 + er and absf(e.global_position.y - fy) < 30.0:
					hit[id] = true
					e.take_damage(7.0)
					if "flash" in e:
						e.flash = 5.0
		else:
			# badger
			if is_boss:
				if absf(e.global_position.x - fx) < 32.0 + er and absf(e.global_position.y - fy) < 26.0:
					e.take_damage(3.0)
					if "flash" in e:
						e.flash = 4.0
			else:
				var id2 := e.get_instance_id()
				if hit.has(id2):
					continue
				if absf(e.global_position.x - fx) < 26.0 + er and absf(e.global_position.y - fy) < 22.0:
					hit[id2] = true
					e.take_damage(8.0)
					if "flash" in e:
						e.flash = 5.0
	f["hit"] = hit
	# soft bullet cancel around body
	if pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(Vector2(fx, fy), 28.0 if is_bull else 30.0, false)

func _tentacle_tick(f: Dictionary) -> void:
	## HTML kraken tentacle thrash
	var pos := Vector2(float(f["x"]), float(f["y"]))
	var reach := float(f.get("reach", 76))
	var tleft := float(f.get("t", 0))
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d := pos.distance_to(e.global_position)
		if d >= reach or d < 0.01:
			continue
		if e.is_in_group("bosses"):
			if int(tleft) % 12 == 0 and e.has_method("take_damage"):
				e.take_damage(2.0)
				if "flash" in e:
					e.flash = 2.0
		else:
			if int(tleft) % 9 == 0 and e.has_method("take_damage"):
				e.take_damage(4.0)
				if "flash" in e:
					e.flash = 4.0
			# pull toward tentacle
			var g := (1.0 - d / reach) * 0.5
			e.global_position += (pos - e.global_position).normalized() * g

func _ram_damage(f: Dictionary, r: float, dmg: float) -> void:
	## Legacy full-circle once-hit (kept for any other callers)
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
	## Generic AoE (legacy)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if Vector2(x, y).distance_to(e.global_position) < r and e.has_method("take_damage"):
			e.take_damage(dmg)
	if pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(Vector2(x, y), r * 0.9, false)

func _blackhole_tick(f: Dictionary, pool: Node, pf: Rect2) -> void:
	## HTML blackhole pull/damage/bullet spiral (shared revenge + melee charge)
	var pos := Vector2(float(f["x"]), float(f["y"]))
	var pull := 155.0
	var dt_bh := float(f.get("dt", 0))
	var col := str(f.get("col", "#3ae66a"))
	# Mumus only — HTML enemies[] loop (not boss)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.is_in_group("bosses"):
			continue
		var d: float = pos.distance_to(e.global_position)
		if d < pull and d > 0.01:
			var g := (1.0 - d / pull) * 2.6
			e.global_position += (pos - e.global_position).normalized() * g
			if d < 26.0 and int(dt_bh) % 8 == 0 and e.has_method("take_damage"):
				e.take_damage(4.0)
				if "flash" in e:
					e.flash = 4.0
	# Boss: chip only (no pull), every 12 frames within pull*0.7
	if int(dt_bh) % 12 == 0:
		for b in get_tree().get_nodes_in_group("bosses"):
			if not is_instance_valid(b):
				continue
			if bool(b.get("dead")):
				continue
			if float(b.get("intro")) > 0.0:
				continue
			if pos.distance_to(b.global_position) < pull * 0.7 and b.has_method("take_damage"):
				b.take_damage(3.0)
				if "flash" in b:
					b.flash = 3.0
	# Bullets: gravity spiral + devour at core (shells keep)
	if pool and pool.has_method("blackhole_pull_bullets"):
		pool.blackhole_pull_bullets(pos, pull, 16.0, col)
	elif pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(pos, 16.0, false)
	# HTML particle stream every 2 frames
	if int(dt_bh) % 2 == 0 and CombatHelpers:
		var a := randf() * TAU
		var rr := pull * (0.5 + randf() * 0.5)
		CombatHelpers.particles.append({
			"x": pos.x + cos(a) * rr, "y": pos.y + sin(a) * rr,
			"vx": -cos(a) * 3.5, "vy": -sin(a) * 3.5,
			"life": 14.0, "c": col if randf() < 0.55 else "#0a3018",
		})

func _bombdrop_explode(x: float, y: float, pool: Node) -> void:
	## HTML bombdrop land: mob 12@62, boss 6@70, shake 4.5, soft clear @54
	if CombatHelpers:
		CombatHelpers.burst(x, y, "#ff9a3c")
		CombatHelpers.burst(x, y, "#ffd27a")
		CombatHelpers.screen_shake = maxf(CombatHelpers.screen_shake, 4.5)
		for i in range(18):
			CombatHelpers.particles.append({
				"x": x, "y": y,
				"vx": (randf() - 0.5) * 11.0, "vy": (randf() - 0.5) * 11.0,
				"life": 24.0, "c": "#ff9a3c" if i % 2 == 0 else "#fff",
			})
	if AudioBus and randf() < 0.5:
		AudioBus.sfx("bomb", 0.65)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		var d := Vector2(x, y).distance_to(e.global_position)
		if e.is_in_group("bosses"):
			if d < 70.0:
				e.take_damage(6.0)
				if "flash" in e:
					e.flash = 5.0
		elif d < 62.0:
			e.take_damage(12.0)
			if "flash" in e:
				e.flash = 6.0
	if pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(Vector2(x, y), 54.0, false)

func _option_like(pool: Node, x: float, y: float, aim: float, wep: String) -> void:
	## HTML optionShot — weapon-matched pellets via FireSystem when available
	var pl = get_tree().get_first_node_in_group("player") if get_tree() else null
	if pl and pl.get("fire_sys") and pl.fire_sys.has_method("option_shot"):
		pl.fire_sys.option_shot(pool, x, y, aim, wep)
		return
	# fallback generic pellet
	pool.spawn(Vector2(x, y), Vector2.from_angle(aim) * 15.0 * FRAME, 1.5, Color("8fb8ff"), TEAM_PLAYER)

func _servitor_tick(f: Dictionary, pool: Node, pf: Rect2) -> bool:
	## HTML servitor hunt AI. Returns true if still alive.
	var pos := Vector2(float(f["x"]), float(f["y"]))
	var tgt_pos := Vector2.ZERO
	var has_tgt := false
	# Prefer non-boss enemies; fall back to boss
	var best_d := 1e12
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.is_in_group("bosses"):
			continue
		var d2 := pos.distance_squared_to(e.global_position)
		if d2 < best_d:
			best_d = d2
			tgt_pos = e.global_position
			has_tgt = true
	if not has_tgt:
		for e in get_tree().get_nodes_in_group("bosses"):
			if not is_instance_valid(e):
				continue
			if bool(e.get("dead")):
				continue
			if float(e.get("intro")) > 0.0:
				continue
			tgt_pos = e.global_position
			has_tgt = true
			break
	var ct := float(f.get("ct", 0))
	if has_tgt:
		var dx := tgt_pos.x - pos.x
		var dy := tgt_pos.y - pos.y
		var d := sqrt(dx * dx + dy * dy)
		if d > 62.0 and d > 0.01:
			pos.x += dx / d * 2.2
			pos.y += dy / d * 2.2
		if int(ct) % 8 == 0 and pool:
			var base := atan2(dy, dx)
			for b in range(-1, 2):
				var a := base + float(b) * 0.16
				var shot = pool.spawn(pos, Vector2.from_angle(a) * 9.0 * FRAME, 3.0, Color("9d6bff"), TEAM_PLAYER)
				if shot and shot.has_method("set_props"):
					shot.set_props({"laser": true, "voidbolt": true, "pshot": true})
			if int(ct) % 24 == 0 and AudioBus:
				AudioBus.sfx("shoot")
	else:
		pos.x += sin(ct * 0.05) * 0.7
		pos.y += cos(ct * 0.04) * 0.7
	pos.x = clampf(pos.x, pf.position.x + 18.0, pf.end.x - 18.0)
	pos.y = clampf(pos.y, pf.position.y + 18.0, pf.end.y - 18.0)
	f["x"] = pos.x
	f["y"] = pos.y
	# soak enemy bullets (HTML: r=13*sz, hp-=5)
	var sz := float(f.get("sz", 2.2))
	var soak_r := 13.0 * sz
	var hp := float(f.get("hp", 26.0))
	if pool and pool.has_method("iter_active"):
		for b in pool.iter_active():
			if not is_instance_valid(b) or int(b.team) != 1:
				continue
			if float(b.get("hp")) > 0.0:
				continue
			if pos.distance_to(b.global_position) < soak_r:
				hp -= 5.0
				b.deactivate()
				if CombatHelpers:
					for i in range(3):
						CombatHelpers.particles.append({
							"x": b.global_position.x, "y": b.global_position.y,
							"vx": (randf() - 0.5) * 3.0, "vy": (randf() - 0.5) * 3.0,
							"life": 10.0, "c": "#9d6bff",
						})
	f["hp"] = hp
	if hp <= 0.0 or float(f.get("t", 0)) <= 0.0:
		if CombatHelpers:
			CombatHelpers.burst(pos.x, pos.y, "#9d6bff")
		return false
	return true

func _nearest_enemy(from: Vector2) -> Vector2:
	## Nearest non-boss mumu position (Vector2.INF if none)
	var best = Vector2.INF
	var bd = 1e12
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.is_in_group("bosses"):
			continue
		var d = from.distance_squared_to(e.global_position)
		if d < bd:
			bd = d
			best = e.global_position
	return best

func get_fx() -> Array:
	return fx
